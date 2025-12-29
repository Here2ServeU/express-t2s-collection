#!/usr/bin/env bash
set -euo pipefail

APP_URL=${APP_URL:-"http://$(kubectl get svc express-web-app -n apps -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"}
CONCURRENCY=${CONCURRENCY:-50}
REQUESTS=${REQUESTS:-20000}

echo "[INFO] Generating traffic to ${APP_URL} ..."
echo "[INFO] Using hey if installed, otherwise curl in a loop."

if command -v hey >/dev/null 2>&1; then
  hey -n ${REQUESTS} -c ${CONCURRENCY} "${APP_URL}"
else
  for i in $(seq 1 ${REQUESTS}); do
    curl -s -o /dev/null "${APP_URL}" &
    if (( i % 100 == 0 )); then
      wait
    fi
  done
  wait
fi

echo "[INFO] Traffic generation complete."
