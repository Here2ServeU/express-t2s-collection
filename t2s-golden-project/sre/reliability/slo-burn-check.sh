    #!/usr/bin/env bash
    set -euo pipefail

    # T2S Reliability: Basic SLO burn calculator (conceptual).
    # Inputs: error_rate (0..1), slo_target (0..1)
    #
    # Usage:
    #   ./sre/reliability/slo-burn-check.sh 0.02 0.99

    ERR="${1:-}"
    SLO="${2:-}"

    if [[ -z "${ERR}" || -z "${SLO}" ]]; then
      echo "Usage: $0 <error_rate> <slo_target>"
      exit 1
    fi

    python3 - <<PY
err=float("${ERR}")
slo=float("${SLO}")
budget=1.0-slo
burn=err/budget if budget>0 else 0
print(f"SLO target: {slo:.4f}")
print(f"Error budget: {budget:.4f}")
print(f"Observed error rate: {err:.4f}")
print(f"Burn rate (err / budget): {burn:.2f}x")
if burn>=1.0:
    print("Status: Budget is being consumed at or above 1x. Consider rollback or mitigation.")
else:
    print("Status: Within budget (for this snapshot).")
PY
