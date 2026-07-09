#!/usr/bin/env bash
# =============================================================================
# setup-k8s-dashboard.sh
# Instala o Headlamp — substituto oficial do Kubernetes Dashboard (arquivado
# em jan/2026) — via Helm, com ServiceAccount e token de acesso.
#
# Na 1ª execução: instala tudo do zero.
# Nas execuções seguintes: detecta instalação existente, gera novo token
# e abre o port-forward direto para acesso à console.
#
# Variáveis de ambiente aceitas (opcional):
#   TOKEN_DURATION   duração do token (ex: 1h, 24h, 8760h) — padrão: 24h
#   NAMESPACE        namespace do Headlamp — padrão: headlamp
#   LOCAL_PORT       porta local do port-forward — padrão: 8080
#   AUTO_YES         se "true", pula todas as confirmações interativas
# =============================================================================

set -euo pipefail

# ─── Cores para output ───────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERRO]${NC}  $*" >&2; exit 1; }
step()    { echo -e "\n${BOLD}──────────────────────────────────────────${NC}"; echo -e "${BOLD}$*${NC}"; echo -e "${BOLD}──────────────────────────────────────────${NC}"; }

# ─── Configurações (sobrescrevíveis via env) ─────────────────────────────────
NAMESPACE="${NAMESPACE:-headlamp}"
RELEASE_NAME="headlamp"
SA_NAME="headlamp-admin"
LOCAL_PORT="${LOCAL_PORT:-8080}"
WAIT_TIMEOUT="120s"
TOKEN_DURATION="${TOKEN_DURATION:-24h}"
AUTO_YES="${AUTO_YES:-false}"

PF_PID=""

# ─── Cleanup ao sair (Ctrl+C, erro, etc.) ────────────────────────────────────
cleanup() {
  if [[ -n "${PF_PID}" ]] && kill -0 "${PF_PID}" 2>/dev/null; then
    warn "Encerrando port-forward (PID: ${PF_PID}) antes de sair..."
    kill "${PF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# ─── Funções utilitárias ──────────────────────────────────────────────────────

confirmar() {
  # confirmar "mensagem" -> retorna 0 (sim) ou 1 (não)
  local msg="$1"
  if [[ "${AUTO_YES}" == "true" ]]; then
    return 0
  fi
  read -rp "$(echo -e "${BOLD}${msg} (s/N): ${NC}")" RESP
  [[ "${RESP,,}" == "s" ]]
}

cluster_parece_local() {
  local cluster="$1"
  case "${cluster}" in
    docker-desktop|docker-for-desktop|minikube|kind-*|k3d-*|rancher-desktop)
      return 0 ;;
    *)
      return 1 ;;
  esac
}

gerar_token_e_acessar() {
  local cluster="$1"
  local titulo="${2:-HEADLAMP DASHBOARD — ACESSO}"

  step "· Gerando novo token de acesso (duração: ${TOKEN_DURATION})"
  TOKEN=$(kubectl -n "${NAMESPACE}" create token "${SA_NAME}" \
    --duration="${TOKEN_DURATION}")
  success "Token gerado."

  mostrar_resumo "${cluster}" "${titulo}"
}

mostrar_resumo() {
  local cluster="$1"
  local titulo="${2:-HEADLAMP DASHBOARD — ACESSO}"

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  printf "${BOLD}${GREEN}║  %-52s ║${NC}\n" "${titulo}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "${BOLD}Cluster:${NC}    ${cluster}"
  echo -e "${BOLD}Namespace:${NC}  ${NAMESPACE}"
  echo ""
  echo -e "${BOLD}${YELLOW}TOKEN DE ACESSO:${NC}"
  echo "─────────────────────────────────────────────────────────"
  echo "${TOKEN}"
  echo "─────────────────────────────────────────────────────────"
  echo ""
  echo -e "${BOLD}Acesse em:${NC}  ${GREEN}http://localhost:${LOCAL_PORT}${NC}"
  echo -e "${YELLOW}ℹ  Cole o token acima na tela de login do Headlamp.${NC}"
  echo ""

  if confirmar "Abrir port-forward agora?"; then
    # Encerra port-forward anterior na mesma porta, se houver
    local old_pid
    old_pid=$(lsof -ti tcp:"${LOCAL_PORT}" 2>/dev/null || true)
    if [[ -n "${old_pid}" ]]; then
      warn "Encerrando port-forward anterior (PID: ${old_pid})..."
      kill "${old_pid}" 2>/dev/null || true
      sleep 1
    fi

    info "Abrindo port-forward em background..."
    kubectl port-forward -n "${NAMESPACE}" \
      svc/"${RELEASE_NAME}" "${LOCAL_PORT}:80" &
    PF_PID=$!
    sleep 2
    success "Port-forward rodando — PID: ${PF_PID}"
    info "Para encerrar: kill ${PF_PID}"
    echo ""
    echo -e "${BOLD}Acesse agora:${NC} ${GREEN}http://localhost:${LOCAL_PORT}${NC}"
    info "Pressione Ctrl+C para encerrar o port-forward e sair do script."
    # Mantém o script vivo para o trap de cleanup funcionar.
    wait "${PF_PID}"
  fi
}

instalar_metrics_server() {
  step "· Verificando Metrics Server"

  if kubectl get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1; then
    success "Metrics Server já está instalado."
    return 0
  fi

  info "Instalando Metrics Server..."

  kubectl apply -f \
    https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

  # Em clusters locais (Docker Desktop, kind, minikube, k3d) o kubelet usa
  # certificado self-signed, então o Metrics Server nunca fica "Ready" sem
  # --kubelet-insecure-tls. Aplicamos o patch de imediato nesses casos para
  # evitar esperar o timeout de rollout à toa.
  if cluster_parece_local "${CLUSTER}"; then
    info "Cluster local detectado — aplicando '--kubelet-insecure-tls' preventivamente..."
    kubectl patch deployment metrics-server \
      -n kube-system \
      --type='json' \
      -p='[
        {
          "op":"add",
          "path":"/spec/template/spec/containers/0/args/-",
          "value":"--kubelet-insecure-tls"
        }
      ]' 2>/dev/null || true
  fi

  info "Aguardando deployment ficar disponível..."
  if ! kubectl rollout status deployment/metrics-server \
      -n kube-system \
      --timeout="${WAIT_TIMEOUT}"; then

    warn "Rollout inicial não completou — tentando patch de compatibilidade..."
    kubectl patch deployment metrics-server \
      -n kube-system \
      --type='json' \
      -p='[
        {
          "op":"add",
          "path":"/spec/template/spec/containers/0/args/-",
          "value":"--kubelet-insecure-tls"
        }
      ]' 2>/dev/null || true

    kubectl rollout restart deployment metrics-server -n kube-system >/dev/null 2>&1 || true

    kubectl rollout status deployment/metrics-server \
      -n kube-system \
      --timeout="${WAIT_TIMEOUT}" || true
  fi

  success "Metrics Server instalado."

  echo ""
  info "Teste das métricas:"
  kubectl top nodes 2>/dev/null || \
    warn "As métricas ainda não estão disponíveis. Aguarde alguns minutos."
}

# ─── Pré-requisitos (sempre verificados) ─────────────────────────────────────
step "· Verificando pré-requisitos"

if ! command -v kubectl &>/dev/null; then
  error "kubectl não encontrado. Instale antes de continuar."
fi
success "kubectl encontrado: $(command -v kubectl)"

if command -v helm &>/dev/null; then
  success "helm encontrado: $(command -v helm)"
else
  warn "helm não encontrado — instalando automaticamente..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
  if command -v helm &>/dev/null; then
    success "helm instalado com sucesso: $(helm version --short)"
  else
    error "Falha ao instalar o helm. Instale manualmente e tente novamente."
  fi
fi

if ! command -v lsof &>/dev/null; then
  warn "lsof não encontrado — a detecção de port-forward anterior será pulada."
fi

if ! kubectl cluster-info &>/dev/null; then
  error "Não foi possível conectar ao cluster. Verifique seu kubeconfig."
fi

CLUSTER=$(kubectl config current-context)
success "Cluster conectado: ${CLUSTER}"

# ─── Aviso de segurança para clusters não-locais ─────────────────────────────
# O ServiceAccount criado mais abaixo recebe cluster-admin. Isso é aceitável
# em clusters locais de desenvolvimento, mas é um risco real em clusters
# remotos ou produtivos — por isso pedimos confirmação explícita.
if ! cluster_parece_local "${CLUSTER}"; then
  warn "Cluster '${CLUSTER}' não parece ser um cluster local de desenvolvimento."
  warn "Este script cria um ServiceAccount com permissões de cluster-admin."
  if ! confirmar "Deseja continuar mesmo assim?"; then
    info "Operação cancelada pelo usuário."
    exit 0
  fi
fi

# ─── Detecta se já está instalado ────────────────────────────────────────────
HEADLAMP_INSTALLED=false
if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" &>/dev/null; then
  HEADLAMP_INSTALLED=true
fi

if [[ "${HEADLAMP_INSTALLED}" == "true" ]]; then
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${CYAN}║   Headlamp já está instalado neste cluster.          ║${NC}"
  echo -e "${BOLD}${CYAN}║   O que deseja fazer?                                ║${NC}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  ${BOLD}1)${NC} Gerar novo token e abrir acesso à console"
  echo -e "  ${BOLD}2)${NC} Atualizar instalação (helm upgrade) + novo token + acesso"
  echo -e "  ${BOLD}3)${NC} Verificar/reinstalar Metrics Server"
  echo -e "  ${BOLD}4)${NC} Sair"
  echo ""
  read -rp "$(echo -e "${BOLD}Escolha [1/2/3/4]: ${NC}")" OPCAO

  case "${OPCAO}" in
    1)
      gerar_token_e_acessar "${CLUSTER}" "HEADLAMP DASHBOARD — ACESSO"
      exit 0
      ;;
    2)
      step "· Atualizando Headlamp via helm upgrade"
      helm repo update
      helm upgrade "${RELEASE_NAME}" headlamp/headlamp \
        --namespace "${NAMESPACE}"
      success "Upgrade concluído."

      info "Aguardando pods após upgrade..."
      kubectl rollout status deployment/"${RELEASE_NAME}" \
        -n "${NAMESPACE}" --timeout="${WAIT_TIMEOUT}" \
        || warn "Timeout — verifique com: kubectl get pods -n ${NAMESPACE}"

      gerar_token_e_acessar "${CLUSTER}" "HEADLAMP DASHBOARD — ATUALIZADO"
      exit 0
      ;;
    3)
      instalar_metrics_server
      exit 0
      ;;
    4)
      info "Saindo."
      exit 0
      ;;
    *)
      warn "Opção inválida. Saindo."
      exit 1
      ;;
  esac
fi

# ─── INSTALAÇÃO COMPLETA (primeira vez) ──────────────────────────────────────

instalar_metrics_server

step "1/5 · Adicionando repositório Helm do Headlamp"

# helm repo add já é idempotente — não falha se o repo já existir.
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/ 2>/dev/null \
  && success "Repositório adicionado." \
  || warn "Repositório 'headlamp' já existia — seguindo em frente."

helm repo update
success "Repositórios atualizados."

step "2/5 · Instalando Headlamp"

helm upgrade --install "${RELEASE_NAME}" headlamp/headlamp \
  --create-namespace \
  --namespace "${NAMESPACE}"

success "Helm release aplicado."

step "3/5 · Aguardando pods ficarem Running (timeout: ${WAIT_TIMEOUT})"

kubectl rollout status deployment/"${RELEASE_NAME}" \
  -n "${NAMESPACE}" --timeout="${WAIT_TIMEOUT}" \
  || warn "Timeout — verifique com: kubectl get pods -n ${NAMESPACE}"

echo ""
info "Status atual dos pods:"
kubectl get pods -n "${NAMESPACE}"

step "4/5 · Criando ServiceAccount '${SA_NAME}' com cluster-admin"

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${SA_NAME}
  namespace: ${NAMESPACE}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${SA_NAME}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: ${SA_NAME}
    namespace: ${NAMESPACE}
EOF

success "ServiceAccount e ClusterRoleBinding criados."

step "5/5 · Gerando token de acesso (duração: ${TOKEN_DURATION})"

TOKEN=$(kubectl -n "${NAMESPACE}" create token "${SA_NAME}" \
  --duration="${TOKEN_DURATION}")

success "Token gerado."

mostrar_resumo "${CLUSTER}" "HEADLAMP DASHBOARD — INSTALAÇÃO CONCLUÍDA"