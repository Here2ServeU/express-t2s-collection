#!/bin/bash
# Install Datadog agent on Kubernetes nodes

helm repo add datadog https://helm.datadoghq.com
helm repo update

helm upgrade --install datadog datadog/datadog \
  --set datadog.apiKey=$DD_API_KEY \
  --set datadog.site="datadoghq.com" \
  --set targetSystem=linux