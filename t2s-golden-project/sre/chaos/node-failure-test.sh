#!/usr/bin/env bash
set -euo pipefail

# T2S Chaos: Simulate node failure by cordoning and draining a node.
# Usage:
#   ./sre/chaos/node-failure-test.sh <node-name> <namespace>
#
# Example:
#   ./sre/chaos/node-failure-test.sh ip-10-0-1-123.ec2.internal default

NODE="${1:-}"
NS="${2:-default}"

if [[ -z "${NODE}" ]]; then
  echo "Usage: $0 <node-name> <namespace>"
  exit 1
fi

echo "Cordoning node: ${NODE}"
kubectl cordon "${NODE}"

echo "Draining node: ${NODE}"
kubectl drain "${NODE}" --ignore-daemonsets --delete-emptydir-data --force

echo "Node drained. Validate SLO impact, alerts, and recovery behaviors."
echo "To restore scheduling later: kubectl uncordon ${NODE}"
