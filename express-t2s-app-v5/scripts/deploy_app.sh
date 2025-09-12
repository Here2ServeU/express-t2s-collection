#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${IMAGE_URI:-}" ]]; then
  echo "Set IMAGE_URI to your ECR image (e.g., 123456789012.dkr.ecr.us-east-1.amazonaws.com/express:<tag>)"
  exit 1
fi

sed -i.bak "s|REPLACE_WITH_IMAGE_URI|$IMAGE_URI|g" k8s/deployment.yaml || true

kubectl apply -f k8s/namespace.yaml
kubectl -n apps apply -f k8s/deployment.yaml -f k8s/service.yaml -f k8s/ingress.yaml
kubectl -n apps rollout status deploy/express-web
