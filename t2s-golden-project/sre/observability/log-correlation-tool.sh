    #!/usr/bin/env bash
    set -euo pipefail

    # T2S Observability: Correlate logs by request ID.
    # This is a local example that scans logs and groups by a correlation key.
    #
    # Usage:
    #   ./sre/observability/log-correlation-tool.sh <logfile> <key-regex>
    #
    # Example:
    #   ./sre/observability/log-correlation-tool.sh data/app.log 'requestId=[a-zA-Z0-9-]+'

    LOG="${1:-}"
    KEY_RE="${2:-requestId=[a-zA-Z0-9-]+}"

    if [[ -z "${LOG}" ]]; then
      echo "Usage: $0 <logfile> <key-regex>"
      exit 1
    fi

    python3 - <<PY
import re, sys
log = open("${LOG}", encoding="utf-8", errors="ignore").read().splitlines()
pat = re.compile(r"${KEY_RE}")
groups = {}
for line in log:
    m = pat.search(line)
    if m:
        k = m.group(0)
        groups.setdefault(k, []).append(line)
for k, lines in sorted(groups.items(), key=lambda kv: len(kv[1]), reverse=True)[:20]:
    print("="*80)
    print(k, f"({len(lines)} lines)")
    for l in lines[:15]:
        print(l)
PY
