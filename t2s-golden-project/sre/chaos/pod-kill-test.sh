#!/usr/bin/env bash
set -euo pipefail

# T2S Chaos: Kill a random pod for a deployment and observe recovery.
# Usage:
#   ./sre/chaos/pod-kill-test.sh <namespace> <deployment-name>
#
# Example:
#   ./sre/chaos/pod-kill-test.sh default express-t2s

NS="${1:-default}"
DEPLOY="${2:-}"

if [[ -z "${DEPLOY}" ]]; then
  echo "Usage: $0 <namespace> <deployment-name>"
  exit 1
fi

echo "Selecting a pod from deployment ${DEPLOY} in namespace ${NS}..."
POD=$(kubectl -n "${NS}" get pods -l "app.kubernetes.io/name=${DEPLOY}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)

if [[ -z "${POD}" ]]; then
  # fallback: match by deployment name label often used by templates
  POD=$(kubectl -n "${NS}" get pods -l "app=${DEPLOY}" -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)
fi

if [[ -z "${POD}" ]]; then
  echo "Could not find a pod for deployment ${DEPLOY}. Check labels in your Helm chart."
  exit 1
fi

echo "Killing pod: ${POD}"
kubectl -n "${NS}" delete pod "${POD}"

echo "Waiting for deployment rollout to stabilize..."
kubectl -n "${NS}" rollout status deploy/"${DEPLOY}" --timeout=180s

echo "Chaos test complete. Validate: SLO burn, alerts, and dashboards."
