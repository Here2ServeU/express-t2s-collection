#!/bin/bash
# Configure SCIM provisioning integration in Okta

OKTA_ORG_URL="https://your-org.okta.com"
OKTA_API_TOKEN=$OKTA_API_TOKEN
SCIM_BASE_URL=$1

if [ -z "$SCIM_BASE_URL" ]; then
  echo "Usage: $0 <SCIM_BASE_URL>"
  exit 1
fi

echo "Setting SCIM provisioning..."

curl -X POST \
"$OKTA_ORG_URL/api/v1/apps" \
-H "Authorization: SSWS $OKTA_API_TOKEN" \
-H "Content-Type: application/json" \
-d "{
  \"name\": \"template_scim_2_0_app\",
  \"label\": \"SRE SCIM Integration\",
  \"settings\": {
    \"app\": {
      \"baseUrl\": \"$SCIM_BASE_URL\",
      \"username\": \"email\"
    }
  },
  \"features\": [
    \"PUSH_NEW_USERS\",
    \"PUSH_PROFILE_UPDATES\",
    \"PUSH_USER_DEACTIVATION\"
  ],
  \"credentials\": {
    \"scheme\": \"TOKEN\",
    \"userName\": \"scim_token_user\",
    \"password\": \"$SCIM_TOKEN\"
  }
}"