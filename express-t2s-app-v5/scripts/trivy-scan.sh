#!/usr/bin/env bash
set -euo pipefail

IMAGE=${IMAGE:-"YOUR_AWS_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/express-v6:latest"}

if ! command -v trivy >/dev/null 2>&1; then
  echo "ERROR: Trivy not installed. See https://aquasecurity.github.io/trivy/"
  exit 1
fi

echo "[INFO] Scanning image: ${IMAGE}"
trivy image --severity HIGH,CRITICAL "${IMAGE}"
