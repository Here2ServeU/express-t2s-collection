#!/usr/bin/env bash
set -euo pipefail
URL="${1:-http://localhost:3000/}"
echo "Sending traffic to: $URL"
echo "Press Ctrl+C to stop."
while true; do
  curl -sS "$URL" >/dev/null || true
done
