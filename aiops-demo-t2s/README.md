# AIOps Demo Repository (Express Web App + Prometheus + Grafana + Slack + Human-Approved Remediation)

This repo is a **complete, copy/paste-ready demo**.

You will run a **containerized Express Web App** with:
- **Prometheus** for metrics scraping
- **Grafana** for dashboards
- **Alertmanager** for alert routing
- **Webhook receiver** that forwards alerts to **Slack**
- A simple **AIOps recommender** (Python) that summarizes the incident and recommends next steps
- A **human-in-the-loop approval** step that triggers remediation only after you approve

---

## End-to-End Platform
1. Start the stack (Docker Compose)
2. Confirm the app is healthy (`/health`)
3. Open Grafana dashboards
4. Stress the app (traffic, errors, CPU burn)
5. Watch Prometheus alerts fire
6. Get Slack notifications
7. Run AIOps recommender to post **recommendations** into Slack
8. Approve remediation (one command)
9. Watch the system recover

---

## Prerequisites
- Docker + Docker Compose
- Python 3.10+
- A Slack workspace where you can create an **Incoming Webhook**
- Optional: `curl` (already installed on macOS/Linux)

---

## Quick Start (5 minutes)

### 1) Clone and enter the repo
```bash
git clone https://github.com/Here2ServeU/aiops-demo-t2s
cd aiops-demo-repo
```

### 2) Create your environment file
```bash
cp .env.example .env
```

Edit `.env` and set:
- `SLACK_WEBHOOK_URL` (Slack Incoming Webhook)
- (optional) `PROMETHEUS_URL` if you run Prometheus elsewhere

### 3) Start the stack
```bash
docker compose up -d --build
```

### 4) Open the services
- Express App: http://localhost:3000
- Prometheus:  http://localhost:9090
- Grafana:     http://localhost:3001  (user/pass: admin/admin)
- Alertmanager:http://localhost:9093

### 5) Confirm healthy baseline
```bash
curl -s http://localhost:3000/health
curl -s http://localhost:3000/metrics | head
```

---

## Trigger Incidents (Stress Scripts)

### A) Traffic spike
```bash
bash scripts/stress_traffic.sh
```

### B) Error spike (causes 500s)
```bash
bash scripts/stress_error.sh
```

### C) CPU burn (simulates high compute)
```bash
bash scripts/stress_cpu.sh
```

---

## AIOps Recommendation + Human Approval

### 1) Run AIOps recommender (posts to Slack)
```bash
python3 scripts/aiops_recommend.py
```

It will:
- Query Prometheus for firing alerts + error rate + request latency
- Post a **summary + recommendations** to Slack
- Create `state/pending_remediation.json` (the approval gate)

### 2) Approve remediation (human-in-the-loop)
```bash
bash scripts/approve.sh
```

Remediation actions (safe demo version):
- Restart the Express app container
- Scale the app up (optional) then return to normal

### 3) Verify recovery
Open Grafana and watch:
- Error rate drop
- Request latency return to baseline
- Alerts resolve

---

## Where to Edit Things
- Alert rules: `prometheus/rules.yml`
- Prometheus config: `prometheus/prometheus.yml`
- Grafana provisioning: `grafana/provisioning/`
- Slack webhook forwarding: `webhook-receiver/`
- AIOps logic: `scripts/aiops_recommend.py`

---

## Safety Notes
This is a **teaching demo**. In real production:
- approvals are done with Slack interactive buttons or ITSM workflows
- remediation uses change-management, RBAC, audit logging
- runbooks are versioned and tested

---

## Common Troubleshooting
### No Slack messages?
- Confirm `.env` has a valid `SLACK_WEBHOOK_URL`
- Check webhook receiver logs:
```bash
docker compose logs -f webhook-receiver
```

### Grafana login?
- Default: `admin / admin`
- If prompted to change password, you can skip for demo

---

## License
MIT (for teaching and reuse).
