#!/usr/bin/env bash
set -euo pipefail

echo "[Remediation] Restarting Express app container..."
docker compose restart app

echo "[Remediation] Scaling up app to 2 replicas for 2 minutes (demo)..."
docker compose up -d --scale app=2

echo "[Remediation] Waiting 120 seconds..."
sleep 120

echo "[Remediation] Scaling back to 1 replica..."
docker compose up -d --scale app=1

echo "[Remediation] Done."
