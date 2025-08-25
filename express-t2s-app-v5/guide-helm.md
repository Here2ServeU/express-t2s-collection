
# Guide: Add Helm Charts to Manage Packages on EKS (Version 5)

This guide helps you use **Helm** to manage Kubernetes packages (charts) for the **express-t2s-app-v5** project. We’ll install tools like NGINX Ingress Controller, Prometheus, and Grafana on your EKS cluster.

---

## Prerequisites

Ensure the following are set up:

- AWS EKS Cluster (see v3 guide)
- `kubectl` configured for your cluster
- `helm` installed on your system: https://helm.sh/docs/intro/install/

---

## Folder Structure

```
express-t2s-app-v5/
├── app/
├── terraform/
├── helm/
│   ├── nginx/
│   ├── prometheus/
│   └── grafana/
└── guide-helm.md
```

---

## Step 1: Add Helm Repositories

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

---

## Step 2: Install NGINX Ingress Controller

```bash
helm install nginx-ingress ingress-nginx/ingress-nginx   --namespace ingress-nginx --create-namespace
```

Verify it:

```bash
kubectl get svc -n ingress-nginx
```

Look for a `LoadBalancer` with an external IP or DNS name.

---

## Step 3: Install Prometheus

```bash
helm install prometheus prometheus-community/prometheus   --namespace monitoring --create-namespace
```

Access Prometheus:

```bash
kubectl port-forward svc/prometheus-server -n monitoring 9090:80
# Visit: http://localhost:9090
```

---

## Step 4: Install Grafana

```bash
helm install grafana grafana/grafana   --namespace monitoring
```

Get admin password:

```bash
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Port forward:

```bash
kubectl port-forward svc/grafana -n monitoring 3000:80
# Visit: http://localhost:3000 (user: admin, password from above)
```

---

## Optional: Uninstall Charts

```bash
helm uninstall nginx-ingress -n ingress-nginx
helm uninstall prometheus -n monitoring
helm uninstall grafana -n monitoring
```

---

## Next Steps

- Add more charts like Kyverno, cert-manager, Loki
- Use Helm values.yaml for custom configuration
- Automate with ArgoCD or GitHub Actions (GitOps — see v6)

---

© 2025 Emmanuel Naweji • Transformed 2 Succeed (T2S)

