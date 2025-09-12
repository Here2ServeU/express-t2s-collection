#!/usr/bin/env bash
set -euo pipefail
DNS=$(kubectl -n apps get ingress express-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
i=0
while [[ -z "$DNS" && $i -lt 30 ]]; do
  i=$((i+1))
  echo "Waiting for ALB... ($i/30)"
  sleep 10
  DNS=$(kubectl -n apps get ingress express-web -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)
done
[[ -z "$DNS" ]] && { echo "Timed out."; exit 1; }
echo "http://$DNS/"
