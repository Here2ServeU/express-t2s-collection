# Datadog APM Setup

This project assumes Datadog APM is the primary tracing solution.

## Steps

1. Enable Datadog APM in the agent (see `datadog-agent-install.sh`).
2. Add the Datadog APM library to the Express app.
3. Configure the Datadog environment variables:
   - `DD_SERVICE`
   - `DD_ENV`
   - `DD_VERSION`
   - `DD_AGENT_HOST`

4. Instrument the app:
   - Wrap the HTTP server.
   - Add manual spans where needed (e.g., external calls, DB operations).

## Outcome

- Distributed traces for each request.
- Service map showing dependencies.
- Latency breakdowns for the critical paths.