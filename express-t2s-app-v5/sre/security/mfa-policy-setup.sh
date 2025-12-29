#!/bin/bash
# Configure MFA policy for production systems with Okta API

OKTA_ORG_URL="https://your-org.okta.com"
OKTA_API_TOKEN=$OKTA_API_TOKEN

echo "Creating Okta MFA policy..."

curl -X POST \
"$OKTA_ORG_URL/api/v1/policies?activate=true" \
-H "Authorization: SSWS $OKTA_API_TOKEN" \
-H "Content-Type: application/json" \
-d '{
  "type": "OKTA_SIGN_ON",
  "name": "Prod-MFA-Required",
  "conditions": {
    "people": { "users": { "exclude": [] } }
  },
  "settings": {
    "authn": {
      "constraints": [],
      "mfa": {
        "okta_password": "REQUIRED",
        "okta_verify": "REQUIRED"
      }
    }
  }
}'