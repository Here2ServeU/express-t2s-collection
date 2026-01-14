#!/usr/bin/env python3
import os
import json
import time
from urllib.parse import urlencode
import urllib.request

PROM = os.getenv("PROMETHEUS_URL", "http://localhost:9090")
SLACK = os.getenv("SLACK_WEBHOOK_URL", "")
CHAN = os.getenv("SLACK_CHANNEL_NAME", "#aiops-demo")

STATE_DIR = os.path.join(os.path.dirname(__file__), "..", "state")
os.makedirs(STATE_DIR, exist_ok=True)
PENDING_PATH = os.path.join(STATE_DIR, "pending_remediation.json")

def prom_query(expr: str):
    qs = urlencode({"query": expr})
    url = f"{PROM}/api/v1/query?{qs}"
    with urllib.request.urlopen(url, timeout=5) as r:
        data = json.loads(r.read().decode("utf-8"))
    if data.get("status") != "success":
        return []
    return data.get("data", {}).get("result", [])

def val(result):
    # Prometheus instant query result: [timestamp, value]
    if not result:
        return 0.0
    try:
        return float(result[0].get("value", [None, "0"])[1])
    except Exception:
        return 0.0

def post_slack(text: str):
    if not SLACK or "hooks.slack.com/services/XXX" in SLACK:
        print("[WARN] SLACK_WEBHOOK_URL not set. Printing message instead:\n")
        print(text)
        return
    payload = json.dumps({"text": text}).encode("utf-8")
    req = urllib.request.Request(SLACK, data=payload, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as r:
        r.read()

def main():
    # Signals
    err_rate = val(prom_query('sum(rate(http_requests_total{status=~"5.."}[30s]))'))
    p95 = val(prom_query('histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[30s])) by (le))'))
    burn = val(prom_query('avg_over_time(demo_cpu_burn_active[30s])'))

    # Firing alerts (simple approach: query ALERTS metric)
    firing = prom_query('ALERTS{alertstate="firing"}')
    firing_names = []
    for item in firing:
        labels = item.get("metric", {})
        firing_names.append(labels.get("alertname", "UnknownAlert"))

    # Build a human-friendly summary
    severity = "LOW"
    if err_rate > 1 or p95 > 0.5 or burn > 0.5 or firing_names:
        severity = "HIGH"

    summary_lines = []
    summary_lines.append(f"*AIOps Recommendation* → {CHAN}")
    summary_lines.append(f"Severity: *{severity}*")
    if firing_names:
        summary_lines.append(f"Firing alerts: {', '.join(sorted(set(firing_names)))}")
    summary_lines.append(f"Signals:")
    summary_lines.append(f"• 5xx error rate: {err_rate:.2f} / sec")
    summary_lines.append(f"• p95 latency: {p95:.2f} sec")
    summary_lines.append(f"• CPU burn active: {burn:.2f} (0..1)")

    recs = []
    if err_rate > 1:
        recs.append("Reduce error rate: check /error traffic, recent changes, and dependency failures.")
        recs.append("Temporary mitigation: restart the app container to clear stuck state.")
    if p95 > 0.5:
        recs.append("High latency: add capacity (scale up) and identify slow endpoints.")
    if burn > 0.5:
        recs.append("CPU burn detected: stop /burn tests, then restart container if needed.")

    if not recs:
        recs.append("System looks stable. No action required.")

    summary_lines.append("Recommendations:")
    for r in recs:
        summary_lines.append(f"• {r}")

    summary_lines.append("")
    summary_lines.append("Human approval required to remediate:")
    summary_lines.append("↳ Run: `bash scripts/approve.sh`")

    # Create approval gate state
    pending = {
        "created_at": int(time.time()),
        "severity": severity,
        "signals": {"error_rate_5xx": err_rate, "p95_latency_sec": p95, "cpu_burn_active": burn},
        "firing_alerts": sorted(set(firing_names)),
        "recommendations": recs,
        "approved": False
    }
    with open(PENDING_PATH, "w", encoding="utf-8") as f:
        json.dump(pending, f, indent=2)

    post_slack("\n".join(summary_lines))
    print(f"[OK] Wrote approval gate: {PENDING_PATH}")

if __name__ == "__main__":
    main()
