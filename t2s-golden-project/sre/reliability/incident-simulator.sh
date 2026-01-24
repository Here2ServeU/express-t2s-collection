    #!/usr/bin/env bash
    set -euo pipefail

    # T2S Reliability: Incident simulator (local).
    # This script generates synthetic "incident events" for demos and alert routing tests.
    #
    # Usage:
    #   ./sre/reliability/incident-simulator.sh 30 0.15
    #
    # Args:
    #   1) duration seconds
    #   2) probability of an error event (0..1)

    DUR="${1:-30}"
    P="${2:-0.15}"

    python3 - <<PY
import random, time, json
dur=int("${DUR}")
p=float("${P}")
start=time.time()
events=[]
while time.time()-start<dur:
    is_err=random.random()<p
    evt={"ts": time.time(), "type": "ERROR" if is_err else "OK"}
    events.append(evt)
    print(json.dumps(evt))
    time.sleep(1)
print(f"Generated {len(events)} events.")
PY
