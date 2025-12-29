#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="aiops"
APP_LABEL="aiops-api"
LOCAL_PORT=8081
CONTAINER_PORT=8080

echo "[INFO] Looking for pod with label app=${APP_LABEL} in namespace ${NAMESPACE}..."

POD=$(kubectl get pod -n "${NAMESPACE}" \
  -l "app=${APP_LABEL}" \
  -o jsonpath="{.items[0].metadata.name}" 2>/dev/null || true)

if [[ -z "${POD}" ]]; then
  echo "[ERROR] No pod found for app=${APP_LABEL} in namespace=${NAMESPACE}"
  exit 1
fi

echo "[INFO] Found pod: ${POD}"
echo "[INFO] Port-forwarding ${POD} ➜ localhost:${LOCAL_PORT}"
kubectl port-forward -n "${NAMESPACE}" "${POD}" ${LOCAL_PORT}:${CONTAINER_PORT}