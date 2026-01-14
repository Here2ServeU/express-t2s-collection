#!/usr/bin/env bash
set -euo pipefail

URL="${1:-http://localhost:3000/error?rate=0.7}"

echo "Hitting error endpoint: ${URL}"
echo "This will create 5xx errors to trigger the HighErrorRate alert."
echo "Press Ctrl+C to stop."

while true; do
  # Use timeouts to prevent hanging connections
  curl -sS --max-time 2 --connect-timeout 1 "${URL}" >/dev/null || true

  # Throttle so we don't crash the container/laptop
  sleep 0.05
done
