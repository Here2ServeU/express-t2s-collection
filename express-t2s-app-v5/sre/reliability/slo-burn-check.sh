#!/bin/bash
# Check Datadog burn rate of an SLO

SLO_ID=$1

curl -s \
"https://api.datadoghq.com/api/v1/slo/$SLO_ID/burn_rate?thresholds=7d,1h" \
-H "DD-API-KEY: $DD_API_KEY" \
-H "DD-APPLICATION-KEY: $DD_APP_KEY"