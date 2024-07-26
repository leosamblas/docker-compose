# Kubernetes Dashboard
    $ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/

# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
    $ helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

Configure token

    $ kubectl create serviceaccount admin-user -n kubernetes-dashboard

    $ kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user

# Create token:

    $ kubectl -n kubernetes-dashboard create token dashboard-user


# To access Dashboard run with Proxy:

    $ kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443 &

# Dashboard will be available at: 
    https://localhost:8443