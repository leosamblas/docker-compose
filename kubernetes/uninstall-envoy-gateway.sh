#!/usr/bin/env bash
# =============================================================================
# uninstall-envoy-gateway.sh
# Remove o Envoy Gateway e todos os recursos associados do Kubernetes
# =============================================================================

set -euo pipefail

# =============================================================================
# Configurações — devem ser iguais às usadas na instalação
# =============================================================================
NAMESPACE="envoy-gateway-system"
HELM_RELEASE="eg"
GATEWAY_CLASS_NAME="envoy"
GATEWAY_NAME="main-gateway"

# =============================================================================
# Cores para output
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

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
  command -v kubectl &>/dev/null || missing+=("kubectl")
  command -v helm    &>/dev/null || missing+=("helm")

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_error "Ferramentas não encontradas: ${missing[*]}"
    exit 1
  fi

  if ! kubectl cluster-info &>/dev/null; then
    log_error "Não foi possível conectar ao cluster Kubernetes."
    exit 1
  fi

  log_success "cluster: $(kubectl config current-context)"
}

# =============================================================================
# Confirmação interativa
# =============================================================================
confirm_uninstall() {
  echo ""
  echo -e "${RED}  ATENÇÃO: Esta operação irá remover:${NC}"
  echo ""
  echo -e "    • Helm release '${HELM_RELEASE}' no namespace '${NAMESPACE}'"
  echo -e "    • GatewayClass '${GATEWAY_CLASS_NAME}'"
  echo -e "    • Gateway '${GATEWAY_NAME}' no namespace '${NAMESPACE}'"
  echo -e "    • Todos os HTTPRoutes e BackendTrafficPolicies do Envoy Gateway"
  echo -e "    • CRDs do Envoy Gateway (gateway.envoyproxy.io)"
  echo -e "    • O namespace '${NAMESPACE}' e todos os seus recursos"
  echo ""
  echo -e "${YELLOW}  Rotas e serviços que dependem do Envoy Gateway irão parar de funcionar.${NC}"
  echo ""
  read -r -p "  Digite 'sim' para confirmar: " confirm

  if [[ "$confirm" != "sim" ]]; then
    echo ""
    log_warn "Operação cancelada pelo usuário."
    exit 0
  fi
}

# =============================================================================
# Remove o Gateway e GatewayClass antes do Helm
# (evita que recursos fiquem orphaned com finalizers travados)
# =============================================================================
remove_gateway_resources() {
  log_step "Removendo Gateway e GatewayClass..."

  # Remove o Gateway
  if kubectl get gateway "${GATEWAY_NAME}" -n "${NAMESPACE}" &>/dev/null; then
    kubectl delete gateway "${GATEWAY_NAME}" -n "${NAMESPACE}" --ignore-not-found=true
    log_success "Gateway '${GATEWAY_NAME}' removido."
  else
    log_warn "Gateway '${GATEWAY_NAME}' não encontrado."
  fi

  # Remove todos os HTTPRoutes gerenciados pelo Envoy em todos os namespaces
  local httproutes
  httproutes=$(kubectl get httproute -A \
    -o jsonpath='{range .items[?(@.spec.parentRefs[*].name=="'"${GATEWAY_NAME}"'")]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' \
    2>/dev/null || true)

  if [[ -n "$httproutes" ]]; then
    log_info "Removendo HTTPRoutes associados ao gateway '${GATEWAY_NAME}'..."
    while IFS='/' read -r ns name; do
      [[ -z "$ns" || -z "$name" ]] && continue
      kubectl delete httproute "${name}" -n "${ns}" --ignore-not-found=true
      log_info "  HTTPRoute ${ns}/${name} removido."
    done <<< "$httproutes"
  else
    log_warn "Nenhum HTTPRoute associado ao gateway encontrado."
  fi

  # Remove BackendTrafficPolicies do Envoy
  local policies
  policies=$(kubectl get backendtrafficpolicies -A \
    -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{end}' \
    2>/dev/null || true)

  if [[ -n "$policies" ]]; then
    log_info "Removendo BackendTrafficPolicies..."
    while IFS='/' read -r ns name; do
      [[ -z "$ns" || -z "$name" ]] && continue
      kubectl delete backendtrafficpolicy "${name}" -n "${ns}" --ignore-not-found=true
      log_info "  BackendTrafficPolicy ${ns}/${name} removido."
    done <<< "$policies"
  fi

  # Remove GatewayClass
  if kubectl get gatewayclass "${GATEWAY_CLASS_NAME}" &>/dev/null; then
    kubectl delete gatewayclass "${GATEWAY_CLASS_NAME}" --ignore-not-found=true
    log_success "GatewayClass '${GATEWAY_CLASS_NAME}' removido."
  else
    log_warn "GatewayClass '${GATEWAY_CLASS_NAME}' não encontrado."
  fi
}

# =============================================================================
# Remove a release Helm do Envoy Gateway
# =============================================================================
uninstall_helm_release() {
  log_step "Removendo Helm release '${HELM_RELEASE}'..."

  if helm status "${HELM_RELEASE}" --namespace "${NAMESPACE}" &>/dev/null; then
    helm uninstall "${HELM_RELEASE}" \
      --namespace "${NAMESPACE}" \
      --wait \
      --timeout 3m
    log_success "Release '${HELM_RELEASE}' removida."
  else
    log_warn "Release '${HELM_RELEASE}' não encontrada. Pulando."
  fi
}

# =============================================================================
# Remove CRDs do Envoy Gateway
# =============================================================================
remove_crds() {
  log_step "Removendo CRDs do Envoy Gateway..."

  local crds
  crds=$(kubectl get crd -o name 2>/dev/null | grep "gateway.envoyproxy.io" || true)

  if [[ -n "$crds" ]]; then
    echo "$crds" | xargs kubectl delete --ignore-not-found=true
    log_success "CRDs do Envoy Gateway removidos."
  else
    log_warn "Nenhum CRD do Envoy Gateway encontrado."
  fi
}

# =============================================================================
# Remove o namespace
# =============================================================================
remove_namespace() {
  log_step "Removendo namespace '${NAMESPACE}'..."

  if kubectl get namespace "${NAMESPACE}" &>/dev/null; then
    # Força remoção de recursos com finalizers travados
    kubectl delete all --all -n "${NAMESPACE}" --ignore-not-found=true 2>/dev/null || true

    kubectl delete namespace "${NAMESPACE}" --timeout=60s
    log_success "Namespace '${NAMESPACE}' removido."
  else
    log_warn "Namespace '${NAMESPACE}' não encontrado. Pulando."
  fi
}

# =============================================================================
# Resumo final
# =============================================================================
print_summary() {
  echo ""
  echo -e "${GREEN}=============================================${NC}"
  echo -e "${GREEN}  Envoy Gateway removido com sucesso!${NC}"
  echo -e "${GREEN}=============================================${NC}"
  echo ""
  echo -e "  O que foi removido:"
  echo -e "    • GatewayClass '${GATEWAY_CLASS_NAME}'"
  echo -e "    • Gateway '${GATEWAY_NAME}'"
  echo -e "    • HTTPRoutes e BackendTrafficPolicies associados"
  echo -e "    • Helm release '${HELM_RELEASE}'"
  echo -e "    • CRDs do Envoy Gateway (gateway.envoyproxy.io)"
  echo -e "    • Namespace '${NAMESPACE}'"
  echo ""
  echo -e "${CYAN}Verifique se ainda há recursos residuais:${NC}"
  echo ""
  echo -e "  kubectl get crd | grep envoy"
  echo -e "  kubectl get gatewayclass"
  echo -e "  kubectl get httproute -A"
  echo -e "  kubectl get namespace ${NAMESPACE}"
  echo ""
}

# =============================================================================
# Main
# =============================================================================
main() {
  echo ""
  echo -e "${CYAN}  Envoy Gateway Uninstaller${NC}"
  echo -e "${CYAN}  Kubernetes Ingress Controller${NC}"
  echo ""

  check_prerequisites
  confirm_uninstall
  remove_gateway_resources
  uninstall_helm_release
  remove_crds
  remove_namespace
  print_summary
}

main "$@"
