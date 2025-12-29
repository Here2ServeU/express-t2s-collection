#!/bin/bash
# Chaos Test: Validate failover between AWS regions

PRIMARY_REGION="us-east-1"
FAILOVER_REGION="us-west-2"

echo "Failing over traffic from $PRIMARY_REGION to $FAILOVER_REGION..."

aws route53 change-resource-record-sets \
  --hosted-zone-id ZXXXXXX \
  --change-batch file://failover.json

echo "Failover triggered."