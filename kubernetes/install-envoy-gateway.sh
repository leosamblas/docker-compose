#!/usr/bin/env bash
# =============================================================================
# install-envoy-gateway.sh
# Instala o Envoy Gateway como ingress controller no Kubernetes
# =============================================================================

set -euo pipefail

# =============================================================================
# Configurações — ajuste conforme seu ambiente
# =============================================================================
ENVOY_GATEWAY_VERSION="v1.8.1"
NAMESPACE="envoy-gateway-system"
GATEWAY_CLASS_NAME="envoy"
GATEWAY_NAME="main-gateway"
GATEWAY_PORT=80

# =============================================================================
# Cores para output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $*"; }
log_step()    { echo -e "\n${CYAN}==>${NC} $*"; }

# =============================================================================
# Verificações de pré-requisitos
# =============================================================================
check_prerequisites() {
  log_step "Verificando pré-requisitos..."

  local missing=()

  if ! command -v kubectl &>/dev/null; then
    missing+=("kubectl")
  fi

  if ! command -v helm &>/dev/null; then
    missing+=("helm")
  fi

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Ferramentas não encontradas: ${missing[*]}"
    log_error "Instale-as antes de continuar."
    exit 1
  fi

  # Verifica conectividade com o cluster
  if ! kubectl cluster-info &>/dev/null; then
    log_error "Não foi possível conectar ao cluster Kubernetes."
    log_error "Verifique se KUBECONFIG está configurado corretamente."
    exit 1
  fi

  log_success "kubectl:  $(kubectl version --client --short 2>/dev/null | head -1)"
  log_success "helm:     $(helm version --short)"
  log_success "cluster:  $(kubectl config current-context)"
}

# =============================================================================
# Instalar o Envoy Gateway via Helm
# =============================================================================
install_envoy_gateway() {
  log_step "Instalando Envoy Gateway ${ENVOY_GATEWAY_VERSION}..."

  # Adiciona o repo OCI não requer `helm repo add`, mas vamos garantir que
  # o namespace exista antes
  kubectl get namespace "${NAMESPACE}" &>/dev/null \
    || kubectl create namespace "${NAMESPACE}"

  if helm status eg --namespace "${NAMESPACE}" &>/dev/null; then
    log_warn "Release 'eg' já existe. Executando upgrade..."
    helm upgrade eg \
      oci://docker.io/envoyproxy/gateway-helm \
      --version "${ENVOY_GATEWAY_VERSION}" \
      --namespace "${NAMESPACE}" \
      --wait \
      --timeout 3m
  else
    helm install eg \
      oci://docker.io/envoyproxy/gateway-helm \
      --version "${ENVOY_GATEWAY_VERSION}" \
      --namespace "${NAMESPACE}" \
      --create-namespace \
      --wait \
      --timeout 3m
  fi

  log_success "Envoy Gateway instalado com sucesso."
}

# =============================================================================
# Aguarda os pods ficarem prontos
# =============================================================================
wait_for_pods() {
  log_step "Aguardando pods do Envoy Gateway ficarem prontos..."

  kubectl rollout status deployment/envoy-gateway \
    --namespace "${NAMESPACE}" \
    --timeout=120s

  log_success "Pods prontos."
}

# =============================================================================
# Criar GatewayClass
# =============================================================================
apply_gateway_class() {
  log_step "Aplicando GatewayClass '${GATEWAY_CLASS_NAME}'..."

  kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: ${GATEWAY_CLASS_NAME}
  annotations:
    app.kubernetes.io/managed-by: install-envoy-gateway.sh
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
EOF

  log_success "GatewayClass '${GATEWAY_CLASS_NAME}' aplicado."
}

# =============================================================================
# Criar Gateway
# =============================================================================
apply_gateway() {
  log_step "Aplicando Gateway '${GATEWAY_NAME}' no namespace '${NAMESPACE}'..."

  kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: ${GATEWAY_NAME}
  namespace: ${NAMESPACE}
  annotations:
    app.kubernetes.io/managed-by: install-envoy-gateway.sh
spec:
  gatewayClassName: ${GATEWAY_CLASS_NAME}
  listeners:
  - name: http
    protocol: HTTP
    port: ${GATEWAY_PORT}
EOF

  log_success "Gateway '${GATEWAY_NAME}' aplicado."
}

# =============================================================================
# Aguarda o Gateway receber um endereço externo
# =============================================================================
wait_for_gateway_address() {
  log_step "Aguardando endereço externo do Gateway (pode levar alguns minutos)..."

  local attempts=0
  local max_attempts=30

  while [[ $attempts -lt $max_attempts ]]; do
    local address
    address=$(kubectl get gateway "${GATEWAY_NAME}" \
      --namespace "${NAMESPACE}" \
      -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || true)

    if [[ -n "$address" ]]; then
      log_success "Gateway disponível em: ${address}:${GATEWAY_PORT}"
      return 0
    fi

    attempts=$((attempts + 1))
    log_info "Aguardando... (${attempts}/${max_attempts})"
    sleep 5
  done

  log_warn "Gateway ainda não tem endereço externo após ${max_attempts} tentativas."
  log_warn "Verifique com: kubectl get gateway ${GATEWAY_NAME} -n ${NAMESPACE}"
}

# =============================================================================
# Resumo final
# =============================================================================
print_summary() {
  local address
  address=$(kubectl get gateway "${GATEWAY_NAME}" \
    --namespace "${NAMESPACE}" \
    -o jsonpath='{.status.addresses[0].value}' 2>/dev/null || echo "<pendente>")

  echo ""
  echo -e "${GREEN}=============================================${NC}"
  echo -e "${GREEN}  Envoy Gateway instalado com sucesso!${NC}"
  echo -e "${GREEN}=============================================${NC}"
  echo ""
  echo -e "  Versão:          ${ENVOY_GATEWAY_VERSION}"
  echo -e "  Namespace:       ${NAMESPACE}"
  echo -e "  GatewayClass:    ${GATEWAY_CLASS_NAME}"
  echo -e "  Gateway:         ${GATEWAY_NAME}"
  echo -e "  Endereço:        ${address}:${GATEWAY_PORT}"
  echo ""
  echo -e "${CYAN}Próximos passos:${NC}"
  echo ""
  echo -e "  1. Crie um HTTPRoute no namespace da sua aplicação:"
  echo ""
  echo -e "     apiVersion: gateway.networking.k8s.io/v1"
  echo -e "     kind: HTTPRoute"
  echo -e "     metadata:"
  echo -e "       name: minha-rota"
  echo -e "       namespace: development"
  echo -e "     spec:"
  echo -e "       parentRefs:"
  echo -e "       - name: ${GATEWAY_NAME}"
  echo -e "         namespace: ${NAMESPACE}"
  echo -e "       rules:"
  echo -e "       - matches:"
  echo -e "         - path:"
  echo -e "             type: PathPrefix"
  echo -e "             value: /minha-app"
  echo -e "         filters:"
  echo -e "         - type: URLRewrite"
  echo -e "           urlRewrite:"
  echo -e "             path:"
  echo -e "               type: ReplacePrefixMatch"
  echo -e "               replacePrefixMatch: /"
  echo -e "         backendRefs:"
  echo -e "         - name: meu-service"
  echo -e "           port: 8080"
  echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
  echo ""
  echo -e "${CYAN}  Envoy Gateway Installer${NC}"
  echo -e "${CYAN}  Kubernetes Ingress Controller${NC}"
  echo ""

  check_prerequisites
  install_envoy_gateway
  wait_for_pods
  apply_gateway_class
  apply_gateway
  wait_for_gateway_address
  print_summary
}

main "$@"
