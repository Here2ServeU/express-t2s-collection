#!/bin/bash
# Create a simulated incident in FireHydrant

TITLE=$1
SEVERITY=$2

curl -X POST "https://api.firehydrant.io/v1/incidents" \
-H "Authorization: Bearer $FH_API_KEY" \
-H "Content-Type: application/json" \
-d "{\"title\": \"$TITLE\", \"severity\": \"$SEVERITY\", \"services\": [\"express-app\"]}"