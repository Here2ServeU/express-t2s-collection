#!/usr/bin/env bash
set -euo pipefail

# T2S Observability: Datadog Agent install (Kubernetes via Helm).
# Requires:
#   - a Datadog API key set as DATADOG_API_KEY
#
# Usage:
#   export DATADOG_API_KEY=xxxx
#   ./sre/observability/datadog-agent-install.sh

if [[ -z "${DATADOG_API_KEY:-}" ]]; then
  echo "DATADOG_API_KEY is not set."
  exit 1
fi

helm repo add datadog https://helm.datadoghq.com
helm repo update

kubectl create ns datadog 2>/dev/null || true

helm upgrade --install datadog-agent datadog/datadog       --namespace datadog       --set datadog.apiKey="${DATADOG_API_KEY}"       --set datadog.site="datadoghq.com"       --set datadog.logs.enabled=true       --set datadog.apm.enabled=true

echo "Datadog agent installed. Next: configure APM and log correlation."
