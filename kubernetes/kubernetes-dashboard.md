# Kubernetes Dashboard
    helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
    helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard --set=metricsScraper.enabled=true

# Fix kubernetes-dashboard metrics
    kubectl patch deployment metrics-server -n kube-system --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# Configure token
    kubectl create serviceaccount admin-user -n kubernetes-dashboard
#   
    kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user

# Create token: 24h token expiration time
    kubectl -n kubernetes-dashboard create token admin-user --duration=24h

# To access Dashboard run with Proxy:
    kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &

# Dashboard will be available at: 
    https://localhost:8443
