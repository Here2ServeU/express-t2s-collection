#!/usr/bin/env bash
set -euo pipefail
URL="${1:-http://localhost:3000/burn?seconds=30}"
echo "Triggering CPU burn: $URL"
curl -sS "$URL" | sed 's/{/\n{/g'
echo "Tip: run this multiple times to keep the burn active."
