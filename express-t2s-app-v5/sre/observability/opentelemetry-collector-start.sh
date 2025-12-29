#!/bin/bash
kubectl apply -f https://raw.githubusercontent.com/open-telemetry/opentelemetry-collector/main/examples/k8s/otel-collector.yaml
echo "OpenTelemetry collector deployed."