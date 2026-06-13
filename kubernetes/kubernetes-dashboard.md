# Headlamp Dashboard (scripted install)

Use the provided script to install Headlamp, create an admin ServiceAccount, generate an access token, and optionally open a local port-forward to the Headlamp UI.

    bash kubernetes/setup-k8s-dashboard.sh

This script will:
- verify `kubectl` and `helm`
- install or upgrade Headlamp via Helm
- install Metrics Server if missing
- create a `headlamp-admin` ServiceAccount with `cluster-admin`
- generate a token and display access instructions
- optionally open `http://localhost:8080`

# Uninstall Headlamp

To remove the Headlamp installation and related resources, run:

    bash kubernetes/uninstall-headlamp.sh

This script will:
- stop any active Headlamp port-forwards
- uninstall the Helm release
- delete the Headlamp namespace
- remove the admin ServiceAccount and ClusterRoleBinding
- delete the Metrics Server resources installed by the script

# Envoy Gateway

The repository also includes scripts to install and uninstall the Envoy Gateway ingress controller for Kubernetes.

To install or upgrade the Envoy Gateway, run:

    bash kubernetes/install-envoy-gateway.sh

This script will:
- verify `kubectl` and `helm`
- create the `envoy-gateway-system` namespace if needed
- install or upgrade the Envoy Gateway Helm release
- wait for the gateway pods to become ready
- apply a `GatewayClass` named `envoy`
- apply a `Gateway` named `main-gateway`
- wait for the gateway to obtain an external address

To remove the Envoy Gateway installation, run:

    bash kubernetes/uninstall-envoy-gateway.sh

This script will:
- verify `kubectl` and `helm`
- delete the `main-gateway` Gateway resource
- delete associated HTTPRoutes and BackendTrafficPolicies
- remove the `envoy` GatewayClass
- uninstall the Envoy Gateway Helm release
- delete the `envoy-gateway-system` namespace
- remove Envoy Gateway CRDs
