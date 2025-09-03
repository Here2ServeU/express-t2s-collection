#!/usr/bin/env bash
set -euo pipefail

REGION="${REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-t2s-eks}"

echo "==> kubeconfig"
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME" >/dev/null

echo "==> Ensure namespace"
kubectl apply -f k8s/namespace.yaml

echo "==> Deploy/Update app"
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

echo "==> Wait for ingress-nginx Service hostname"
for i in {1..60}; do
  host="$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
  if [ -n "$host" ]; then
    echo "NGINX Ingress LB: $host"
    echo "Try:  curl -I http://$host/"
    exit 0
  fi
  echo " ... waiting ($i/60)"
  sleep 5
done

echo "ERROR: NGINX ingress LoadBalancer hostname not ready."
kubectl -n ingress-nginx get svc ingress-nginx-controller -o wide || true
exit 1
