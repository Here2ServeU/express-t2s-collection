# Log Correlation Design

Goal: link logs, traces, and metrics for fast incident triage.

## Strategy

- Ensure each request has a correlation ID.
- Add the correlation ID to:
  - HTTP headers.
  - Log entries.
  - Traces (as tags).
- Configure log pipelines in Datadog to parse and index correlation IDs.
- Use the `log-correlation-tool.sh` script to fetch logs for a given trace ID.

Result: during an incident, you can move from:
- High-level SLO burn → specific trace → correlated logs → probable root cause.