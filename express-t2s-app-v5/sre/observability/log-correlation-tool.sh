#!/bin/bash
# Extract correlated logs for a trace ID using Datadog API

TRACE_ID=$1

curl -X POST \
"https://api.datadoghq.com/api/v2/logs/events/search" \
-H "DD-API-KEY: $DD_API_KEY" \
-H "DD-APPLICATION-KEY: $DD_APP_KEY" \
-d "{\"filter\": {\"query\": \"trace_id:$TRACE_ID\"}}"