#!/usr/bin/env bash

set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Configurações
# ─────────────────────────────────────────────────────────────

NAMESPACE="headlamp"
RELEASE_NAME="headlamp"
SA_NAME="headlamp-admin"

# ─────────────────────────────────────────────────────────────
# Cores
# ─────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }

# ─────────────────────────────────────────────────────────────
# Verificações
# ─────────────────────────────────────────────────────────────

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl não encontrado."
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  echo "Não foi possível conectar ao cluster."
  exit 1
fi

CLUSTER=$(kubectl config current-context)

echo ""
echo -e "${BOLD}${RED}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${RED}║           REMOÇÃO COMPLETA DO HEADLAMP             ║${NC}"
echo -e "${BOLD}${RED}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BOLD}Cluster:${NC} ${CLUSTER}"
echo ""
echo "Serão removidos:"
echo " - Headlamp (Helm)"
echo " - Namespace ${NAMESPACE}"
echo " - ServiceAccount ${SA_NAME}"
echo " - ClusterRoleBinding ${SA_NAME}"
echo " - Metrics Server"
echo ""

read -rp "Deseja continuar? (s/N): " CONFIRM

if [[ "${CONFIRM,,}" != "s" ]]; then
  echo "Operação cancelada."
  exit 0
fi

# ─────────────────────────────────────────────────────────────
# Encerra port-forwards ativos
# ─────────────────────────────────────────────────────────────

info "Verificando port-forwards ativos..."

PF_PIDS=$(pgrep -f "kubectl port-forward.*headlamp" || true)

if [[ -n "${PF_PIDS}" ]]; then
  warn "Encerrando port-forwards..."
  kill ${PF_PIDS} 2>/dev/null || true
fi

# ─────────────────────────────────────────────────────────────
# Remove Headlamp
# ─────────────────────────────────────────────────────────────

if command -v helm >/dev/null 2>&1; then
  if helm status "${RELEASE_NAME}" -n "${NAMESPACE}" >/dev/null 2>&1; then
    info "Removendo release Helm..."
    helm uninstall "${RELEASE_NAME}" -n "${NAMESPACE}"
    success "Release removida."
  else
    warn "Release não encontrada."
  fi
fi

# ─────────────────────────────────────────────────────────────
# Remove RBAC
# ─────────────────────────────────────────────────────────────

info "Removendo ServiceAccount..."
kubectl delete serviceaccount "${SA_NAME}" \
  -n "${NAMESPACE}" \
  --ignore-not-found=true

info "Removendo ClusterRoleBinding..."
kubectl delete clusterrolebinding "${SA_NAME}" \
  --ignore-not-found=true

# ─────────────────────────────────────────────────────────────
# Remove Namespace
# ─────────────────────────────────────────────────────────────

if kubectl get namespace "${NAMESPACE}" >/dev/null 2>&1; then
  info "Removendo namespace ${NAMESPACE}..."
  kubectl delete namespace "${NAMESPACE}" --wait=false
else
  warn "Namespace não existe."
fi

# ─────────────────────────────────────────────────────────────
# Remove Metrics Server
# ─────────────────────────────────────────────────────────────

if kubectl get deployment metrics-server -n kube-system >/dev/null 2>&1; then
  info "Removendo Metrics Server..."

  kubectl delete -f \
    https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml \
    --ignore-not-found=true

  success "Metrics Server removido."
else
  warn "Metrics Server não encontrado."
fi

# ─────────────────────────────────────────────────────────────
# Resultado
# ─────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${GREEN}║                REMOÇÃO CONCLUÍDA                   ║${NC}"
echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""

echo "Validações sugeridas:"
echo ""
echo "kubectl get ns"
echo "kubectl get deployments -A | grep headlamp"
echo "kubectl get deployment metrics-server -n kube-system"
echo ""
