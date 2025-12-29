# SRE Scenario Playbook

This playbook documents real-world SRE scenarios and example answers using the STAR method. It is written to model large-scale streaming or high-traffic environments.

## 1. Streaming Degradation or Latency Spike

**Approach**
- Check SLO dashboards and burn rates.
- Correlate metrics: latency, error rate, saturation.
- Inspect traces for slow dependencies.
- Validate autoscaler behavior and capacity.
- Confirm regional health and DNS/ingress behavior.
- Trigger incident tooling (e.g., FireHydrant).
- Communicate impact, actions, and ETA clearly.

**Key Line**
> “My priority is restoring user experience quickly while collecting enough data to prevent recurrence.”

---

## 2. Defining SLOs for a New Product

**Steps**
- Map the end-to-end user journey.
- Identify SLIs: latency, error rate, availability, success ratio.
- Define SLO targets and time windows.
- Connect alerts to error-budget burn rates instead of raw thresholds.
- Integrate SLO health into release and on-call decisions.

---

## 3. Leading a Major Incident

**Steps**
- Activate incident tooling and declare an incident.
- Assign roles: Incident Commander, Communications, Scribe, SMEs.
- Use unified dashboards (Datadog) as the single pane of glass.
- Communicate every 5–10 minutes with clear, concise updates.
- Mitigate first; root cause analysis second.
- Conduct a blameless post-incident review with action items.

---

## 4. Team Lacks Monitoring Discipline

**Response**
- Start with understanding the team’s pain points.
- Provide a starter kit: baseline dashboards, alert templates, SLO examples.
- Pair with the team to instrument the most critical user journeys.
- Review on-call experiences and adjust alerting to reduce noise.
- Iterate and coach so reliability ownership stays with the service team.

---

## 5. Reducing High-Severity Incidents by 50%

**Program Components**
- SLO-based alerts instead of low-level noise.
- Auto-remediation for known failure modes.
- Standardized observability across services.
- Chaos experiments to validate remediation and failover paths.
- Regular incident drills and training.
- Actionable postmortems with follow-through.

---

## 6. Preparing for a Critical Launch or Event

**Checklist**
- Load and stress testing complete with pass criteria.
- DR and failover paths validated.
- SLOs and dashboards reviewed as “go/no-go” gates.
- Synthetic tests configured for critical paths.
- Autoscaling thresholds tuned based on historic and test data.
- War room and escalation paths defined.
- Pre-event and in-event health checks documented with clear owners.