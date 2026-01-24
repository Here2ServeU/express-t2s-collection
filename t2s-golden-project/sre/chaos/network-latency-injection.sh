#!/usr/bin/env bash
set -euo pipefail

# T2S Chaos: Inject network latency on a node interface using tc netem.
# Run ONLY in non-production environments.
#
# Usage:
#   sudo ./sre/chaos/network-latency-injection.sh <iface> <latency_ms> <duration_seconds>
#
# Example:
#   sudo ./sre/chaos/network-latency-injection.sh eth0 200 60

IFACE="${1:-}"
LAT="${2:-200}"
DUR="${3:-60}"

if [[ -z "${IFACE}" ]]; then
  echo "Usage: sudo $0 <iface> <latency_ms> <duration_seconds>"
  exit 1
fi

echo "Injecting ${LAT}ms latency on ${IFACE} for ${DUR}s"
tc qdisc add dev "${IFACE}" root netem delay "${LAT}ms" 2>/dev/null || true
sleep "${DUR}"
echo "Removing latency injection"
tc qdisc del dev "${IFACE}" root netem 2>/dev/null || true
echo "Done"
