#!/usr/bin/env bash
set -euo pipefail

# T2S Chaos: Simulate dependency failure by scaling a dependency deployment to zero.
# Usage:
#   ./sre/chaos/dependency-failure-simulation.sh <namespace> <dependency-deploy> <duration_seconds>
#
# Example:
#   ./sre/chaos/dependency-failure-simulation.sh default redis 60

NS="${1:-default}"
DEP="${2:-}"
DUR="${3:-60}"

if [[ -z "${DEP}" ]]; then
  echo "Usage: $0 <namespace> <dependency-deploy> <duration_seconds>"
  exit 1
fi

echo "Scaling dependency ${DEP} to 0 in ${NS} for ${DUR}s"
kubectl -n "${NS}" scale deploy/"${DEP}" --replicas=0
sleep "${DUR}"
echo "Restoring dependency ${DEP} to 1 replica"
kubectl -n "${NS}" scale deploy/"${DEP}" --replicas=1
kubectl -n "${NS}" rollout status deploy/"${DEP}" --timeout=180s
echo "Done. Validate retries, circuit breakers, and alert routing."
