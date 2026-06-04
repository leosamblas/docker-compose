#!/usr/bin/env bash
# =============================================================================
# setup-k8s-dashboard.sh
# Instala o Headlamp — substituto oficial do Kubernetes Dashboard (arquivado
# em jan/2026) — via Helm, com ServiceAccount e token de acesso.
#
# Na 1ª execução: instala tudo do zero.
# Nas execuções seguintes: detecta instalação existente, gera novo token
# e abre o port-forward direto para acesso à console.
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

# ─── Configurações (edite se necessário) ─────────────────────────────────────
NAMESPACE="headlamp"
RELEASE_NAME="headlamp"
SA_NAME="headlamp-admin"
LOCAL_PORT="8080"
WAIT_TIMEOUT="120s"
TOKEN_DURATION="24h"    # duração do token (ex: 1h, 24h, 8760h para 1 ano)

# ─── Funções utilitárias ──────────────────────────────────────────────────────

gerar_token_e_acessar() {
  local cluster="$1"

  step "· Gerando novo token de acesso (duração: ${TOKEN_DURATION})"
  TOKEN=$(kubectl -n "${NAMESPACE}" create token "${SA_NAME}" \
    --duration="${TOKEN_DURATION}")
  success "Token gerado."

  mostrar_resumo "${cluster}"
}

mostrar_resumo() {
  local cluster="$1"

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║           HEADLAMP DASHBOARD — ACESSO               ║${NC}"
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

  read -rp "$(echo -e "${BOLD}Abrir port-forward agora? (s/N): ${NC}")" OPEN_PF
  if [[ "${OPEN_PF,,}" == "s" ]]; then
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

  info "Aguardando deployment ficar disponível..."

  kubectl rollout status deployment/metrics-server \
    -n kube-system \
    --timeout="${WAIT_TIMEOUT}" || true

  # Adiciona suporte para clusters com TLS de kubelet não configurado
  info "Aplicando configuração compatível com clusters locais..."

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

if ! kubectl cluster-info &>/dev/null; then
  error "Não foi possível conectar ao cluster. Verifique seu kubeconfig."
fi

CLUSTER=$(kubectl config current-context)
success "Cluster conectado: ${CLUSTER}"

instalar_metrics_server

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
  echo -e "  ${BOLD}3)${NC} Sair"
  echo ""
  read -rp "$(echo -e "${BOLD}Escolha [1/2/3]: ${NC}")" OPCAO

  case "${OPCAO}" in
    1)
      gerar_token_e_acessar "${CLUSTER}"
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

      gerar_token_e_acessar "${CLUSTER}"
      exit 0
      ;;
    3)
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

step "1/5 · Adicionando repositório Helm do Headlamp"

if helm repo list 2>/dev/null | grep -q "headlamp"; then
  warn "Repositório 'headlamp' já existe — atualizando..."
else
  helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
  success "Repositório adicionado."
fi

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

# Ajusta título do resumo para instalação nova
mostrar_resumo() {
  local cluster="$1"

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
  echo -e "${BOLD}${GREEN}║        HEADLAMP DASHBOARD — INSTALAÇÃO CONCLUÍDA    ║${NC}"
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

  read -rp "$(echo -e "${BOLD}Abrir port-forward agora? (s/N): ${NC}")" OPEN_PF
  if [[ "${OPEN_PF,,}" == "s" ]]; then
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
  fi
}

mostrar_resumo "${CLUSTER}"