#!/usr/bin/env bash
set -euo pipefail

STATE_FILE="state/pending_remediation.json"

if [[ ! -f "$STATE_FILE" ]]; then
  echo "[ERROR] No pending remediation found. Run: python3 scripts/aiops_recommend.py"
  exit 1
fi

echo "[Approval] Pending remediation found:"
cat "$STATE_FILE" | sed -e 's/^/  /'

echo ""
echo "[Approval] You are approving remediation now..."
python3 - <<'PY'
import json, time
p="state/pending_remediation.json"
data=json.load(open(p))
data["approved"]=True
data["approved_at"]=int(time.time())
json.dump(data, open(p,"w"), indent=2)
print("[OK] Approval recorded.")
PY

bash scripts/remediate.sh
