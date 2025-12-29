# SRE Toolkit (Version 7 Consultancy Layer)

This `sre/` directory contains the Site Reliability Engineering toolkit layered on top of the existing Express Web App infrastructure (EKS, ECR, infra/).

It is organized into five domains:
- `aiops/` – ML-based forecasting, anomaly detection, autoscaling recommendations, log clustering.
- `chaos/` – Chaos engineering scripts to validate resilience and failover.
- `observability/` – Datadog, OpenTelemetry, and logging integration scripts.
- `reliability/` – SLO, error budget, incident simulation, and governance playbooks.
- `security/` – Identity and access governance (Okta), MFA, SCIM, RBAC for SRE operations.

You can use this toolkit as:
- A reference architecture for SRE consulting engagements.
- A teaching lab for SRE, AIOps, and DevOps training.
- A portfolio project for Fortune 500 / FAANG interviews to demonstrate end-to-end reliability thinking.