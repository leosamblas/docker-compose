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
