# OpenTelemetry Tracing Setup

This project can integrate OpenTelemetry alongside Datadog.

## Steps

1. Deploy the OpenTelemetry Collector (`opentelemetry-collector-start.sh`).
2. Add OpenTelemetry SDK to the Express app.
3. Export traces to:
   - Datadog
   - Or another backend (Jaeger, Tempo, etc.)

## Benefits

- Vendor-neutral tracing.
- Easier migration or multi-vendor observability strategies.
- Unified telemetry model across languages and services.