# Datadog, SLO, and Chaos Engineering Mastery Sheet
Senior SRE Preparation – Streaming and High-Traffic Systems

## 1. Datadog Cheat Sheet

### Key Components

**APM (Traces)**
- Service maps
- Latency breakdowns
- Dependency analysis
- Request-level performance during peak traffic

**Metrics**
- CPU, memory, request throughput
- Error rate and saturation
- Video playback or key business metrics

**Logs**
- Structured logs
- Log pipelines and parsing
- Trace-to-log correlation

**Dashboards**
- SLO dashboards
- Latency heatmaps
- Playback/transaction health monitoring

**RUM (Real User Monitoring)**
- Page load
- Stream or transaction quality
- Buffering / UX-impacting events

**Synthetic Tests**
- Pre-peak, mid-peak, and post-peak availability tests
- API uptime monitoring

**Watchdog (ML)**
- Outlier and anomaly detection
- Pattern recognition during traffic spikes

### Senior-Level Talking Points

- “I create Datadog observability packs that standardize dashboards, alerts, and tracing patterns across teams.”
- “I use burn-rate alerts instead of raw threshold alerts to tie monitoring to SLOs and user experience.”
- “I rely on APM + RUM to detect performance regressions during peak traffic windows.”
- “I design synthetic tests for critical user journeys and run them before and during major events.”
- “I leverage Watchdog insights to detect anomalies before they escalate into incidents.”

---

## 2. SLO and Error Budget Cheat Sheet

### Example SLOs

- **Stream start / API response SLO:** 99% complete under 3 seconds.
- **Buffering / failure ratio SLO:** Less than 0.5% of total session time.
- **Error rate SLO:** Less than 0.1% of user-visible failures.
- **Critical API latency SLO:** P95 under 200 ms.
- **Event window uptime SLO:** 99.99% uptime during defined critical windows.

### How to Talk About SLOs

- Define SLOs from the **user’s perspective**, not just node or pod metrics.
- Identify SLIs first (latency, error rate, availability, buffering, success rate).
- Use SLOs to guide:
  - Alerting (burn rates).
  - Deployment gates (freeze when error budget is consumed).
  - Product trade-offs (shipping vs hardening).
- Integrate SLO dashboards into team retros and operational reviews.

### Error Budget Rules of Thumb

- 14x burn → Immediate page (something is seriously wrong).
- 4x burn → Notify engineering leadership.
- 2x burn → Engage product to align priorities (features vs reliability).

---

## 3. Chaos Engineering Cheat Sheet

### Common Experiments

- Node failure simulation.
- Pod kill tests.
- Region or AZ failover.
- Network latency injection.
- Packet loss simulation.
- Cache or database dependency failures.
- Traffic surge / spike tests.
- DNS degradation tests.

**Positioning line:**

> “I run hypothesis-driven chaos experiments to validate SLOs, uncover unknown failure modes, and ensure the user experience remains stable even under failure conditions.”

---

## 4. Go / Okta / Terraform Micro-Cheat Sheet

See `go-okta-terraform-microcheatsheet.md` in this folder for language/tool-specific talking points and patterns.

---

## 5. Usage in This Repo

This cheat sheet backs the `sre/` scripts and is used as:
- A “prep deck” for interviews.
- An internal SRE consultancy guide.
- A training reference for teams learning Datadog, SLOs, and chaos engineering.