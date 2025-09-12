#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# cleanup.sh — Force-clean a VPC and its dependencies
# Includes:
#   Fix-A: Aggressive ENI cleanup (detach/terminate if needed)
#   Fix-B: Revoke Security Group references before deletion
# Requirements: aws, jq, base64, bash
# ============================================================

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' is required"; exit 1; }; }
need aws
need jq
need base64

AWS_REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null || echo 'us-east-1')}"
VPC_ID="${VPC_ID:-}"

if [[ -z "$VPC_ID" ]]; then
  echo "[INFO] VPC_ID not provided; attempting to detect default VPC in ${AWS_REGION}…"
  VPC_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" \
    --filters Name=isDefault,Values=true \
    --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)"
  [[ "$VPC_ID" == "None" ]] && VPC_ID=""
fi

if [[ -z "$VPC_ID" ]]; then
  echo "ERROR: Could not determine VPC_ID. Set env VPC_ID or pass it explicitly: VPC_ID=vpc-xxxx AWS_REGION=us-east-1 bash cleanup.sh"
  exit 1
fi

FORCE_TERMINATE_INSTANCES="${FORCE_TERMINATE_INSTANCES:-false}"
MAX_RETRIES="${MAX_RETRIES:-30}"
SLEEP_SECS="${SLEEP_SECS:-10}"

echo "[START] Force cleanup for VPC: ${VPC_ID} in ${AWS_REGION}"
aws ec2 describe-vpcs --region "$AWS_REGION" --vpc-ids "$VPC_ID" >/dev/null

# 0) Helm/K8s best-effort (ignore failures)
if command -v helm >/dev/null 2>&1; then
  echo "[0] Helm best-effort uninstalls…"
  helm -n ingress-nginx uninstall ingress-nginx || true
  helm -n kube-system   uninstall aws-load-balancer-controller || true
fi
if command -v kubectl >/dev/null 2>&1; then
  echo "[0] Deleting Services of type LoadBalancer…"
  SVCs="$(kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type=="LoadBalancer")]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' 2>/dev/null || true)"
  if [[ -n "$SVCs" ]]; then
    while read -r ns name; do
      [[ -z "$ns" || -z "$name" ]] && continue
      echo "   - deleting svc $ns/$name"
      kubectl -n "$ns" delete svc "$name" --wait=false || true
    done <<< "$SVCs"
  fi
fi

# 1) ELBv2 (ALB/NLB)
echo "[1] Deleting ELBv2 (ALB/NLB) and listeners…"
for _ in $(seq 1 "$MAX_RETRIES"); do
  ARNS="$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
    --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text || true)"
  if [[ -z "$ARNS" ]]; then echo "   No ELBv2 found (ok)."; break; fi
  for arn in $ARNS; do
    echo "   - deleting listeners for $arn"
    LST="$(aws elbv2 describe-listeners --region "$AWS_REGION" --load-balancer-arn "$arn" \
      --query 'Listeners[].ListenerArn' --output text 2>/dev/null || true)"
    for l in $LST; do aws elbv2 delete-listener --region "$AWS_REGION" --listener-arn "$l" || true; done
    echo "   - deleting load balancer $arn"
    aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$arn" || true
  done
  echo "   Waiting for ELBv2 to disappear…"; sleep "$SLEEP_SECS"
done

# 2) Classic ELBs
echo "[2] Deleting Classic ELBs (if any) in VPC…"
CLBS="$(aws elb describe-load-balancers --region "$AWS_REGION" \
  --query 'LoadBalancerDescriptions[].{Name:LoadBalancerName,Subnets:Subnets}' \
  --output json 2>/dev/null | jq -r '.[]? | @base64' || true)"
if [[ -n "$CLBS" ]]; then
  while read -r row; do
    d() { echo "$row" | base64 --decode | jq -r "$1"; }
    name="$(d '.Name')"
    subnets_json="$(d '.Subnets')"
    in_vpc=0
    for s in $(echo "$subnets_json" | jq -r '.[]'); do
      svpc="$(aws ec2 describe-subnets --region "$AWS_REGION" --subnet-ids "$s" \
        --query 'Subnets[0].VpcId' --output text 2>/dev/null || true)"
      [[ "$svpc" == "$VPC_ID" ]] && in_vpc=1
    done
    if [[ "$in_vpc" == "1" ]]; then
      echo "   - deleting Classic ELB $name"
      aws elb delete-load-balancer --region "$AWS_REGION" --load-balancer-name "$name" || true
    fi
  done <<< "$CLBS"
else
  echo "   No Classic ELBs found (ok)."
fi

# 3) Orphaned Target Groups
echo "[3] Deleting orphaned Target Groups…"
TGS="$(aws elbv2 describe-target-groups --region "$AWS_REGION" \
  --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text || true)"
for tg in $TGS; do aws elbv2 delete-target-group --region "$AWS_REGION" --target-group-arn "$tg" || true; done

# 4) NAT + EIPs
echo "[4] Deleting NAT Gateways and collecting EIPs…"
declare -a NAT_EIPS=()
NGWS="$(aws ec2 describe-nat-gateways --region "$AWS_REGION" \
  --filter Name=vpc-id,Values="$VPC_ID" \
  --query 'NatGateways[].NatGatewayId' --output text || true)"
for ngw in $NGWS; do
  ALLOCS="$(aws ec2 describe-nat-gateways --region "$AWS_REGION" --nat-gateway-ids "$ngw" \
    --query 'NatGateways[0].NatGatewayAddresses[].AllocationId' --output text || true)"
  for a in $ALLOCS; do [[ -n "$a" && "$a" != "None" ]] && NAT_EIPS+=("$a"); done
  echo "   - deleting NAT Gateway $ngw"
  aws ec2 delete-nat-gateway --region "$AWS_REGION" --nat-gateway-id "$ngw" || true
done
for _ in $(seq 1 "$MAX_RETRIES"); do
  LEFT="$(aws ec2 describe-nat-gateways --region "$AWS_REGION" \
    --filter Name=vpc-id,Values="$VPC_ID" Name=state,Values=pending,available,deleting \
    --query 'NatGateways[].NatGatewayId' --output text || true)"
  [[ -z "$LEFT" ]] && { echo "   NAT Gateways gone."; break; }
  echo "   Waiting for NAT GW deletion…"; sleep "$SLEEP_SECS"
done
if [[ "${#NAT_EIPS[@]}" -gt 0 ]]; then
  echo "[4b] Releasing NAT EIPs: ${NAT_EIPS[*]}"
  for alloc in "${NAT_EIPS[@]}"; do
    ASSOC="$(aws ec2 describe-addresses --region "$AWS_REGION" --allocation-ids "$alloc" \
      --query 'Addresses[0].AssociationId' --output text 2>/dev/null || true)"
    [[ "$ASSOC" != "None" && -n "$ASSOC" && "$ASSOC" != "null" ]] && \
      aws ec2 disassociate-address --region "$AWS_REGION" --association-id "$ASSOC" || true
    aws ec2 release-address --region "$AWS_REGION" --allocation-id "$alloc" || true
  done
fi

# 5) VPC endpoints
echo "[5] Deleting VPC Endpoints…"
VPCE_IDS="$(aws ec2 describe-vpc-endpoints --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'VpcEndpoints[].VpcEndpointId' --output text || true)"
[[ -n "$VPCE_IDS" ]] && aws ec2 delete-vpc-endpoints --region "$AWS_REGION" --vpc-endpoint-ids $VPCE_IDS || true

# 6) Instances (optional)
if [[ "$FORCE_TERMINATE_INSTANCES" == "true" ]]; then
  echo "[6] Terminating EC2 instances in VPC…"
  INSTANCE_IDS="$(aws ec2 describe-instances --region "$AWS_REGION" \
    --filters Name=vpc-id,Values="$VPC_ID" Name=instance-state-name,Values=pending,running,stopping,stopped \
    --query 'Reservations[].Instances[].InstanceId' --output text || true)"
  if [[ -n "$INSTANCE_IDS" ]]; then
    aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids $INSTANCE_IDS || true
    echo "   Waiting for instances to terminate…"
    aws ec2 wait instance-terminated --region "$AWS_REGION" --instance-ids $INSTANCE_IDS || true
  fi
else
  echo "[6] Skipping EC2 termination (set FORCE_TERMINATE_INSTANCES=true to enable)."
fi

# Fix-A: Aggressive ENI cleanup
echo "[Fix-A] Repeated ENI cleanup (detach/terminate if needed)…"
for _ in $(seq 1 "$MAX_RETRIES"); do
  ENI_JSON="$(aws ec2 describe-network-interfaces --region "$AWS_REGION" \
    --filters Name=vpc-id,Values="$VPC_ID" \
    --query 'NetworkInterfaces[].{Id:NetworkInterfaceId,Status:Status,IfType:InterfaceType,Desc:Description,Att:Attachment,Groups:Groups[*].GroupId}' \
    --output json || echo '[]')"
  ENI_COUNT="$(echo "$ENI_JSON" | jq 'length')"
  [[ "$ENI_COUNT" -eq 0 ]] && { echo "   No ENIs left."; break; }

  echo "   Remaining ENIs: $ENI_COUNT"
  echo "$ENI_JSON" | jq -c '.[]' | while read -r eni; do
    ID="$(echo "$eni" | jq -r '.Id')"
    STATUS="$(echo "$eni" | jq -r '.Status')"
    IFTYPE="$(echo "$eni" | jq -r '.IfType')"
    DESC="$(echo "$eni" | jq -r '.Desc')"
    ATT_ID="$(echo "$eni" | jq -r '.Att.AttachmentId // empty')"
    INST_ID="$(echo "$eni" | jq -r '.Att.InstanceId // empty')"

    if [[ "$STATUS" == "available" ]]; then
      echo "     - deleting available ENI $ID"
      aws ec2 delete-network-interface --region "$AWS_REGION" --network-interface-id "$ID" || true
      continue
    fi
    if [[ -n "$INST_ID" ]]; then
      if [[ "$FORCE_TERMINATE_INSTANCES" == "true" ]]; then
        echo "     - ENI $ID attached to $INST_ID → terminating instance"
        aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids "$INST_ID" || true
      else
        if [[ -n "$ATT_ID" ]]; then
          echo "     - detaching ENI $ID (attachment $ATT_ID) from $INST_ID"
          aws ec2 detach-network-interface --region "$AWS_REGION" --attachment-id "$ATT_ID" || true
        else
          echo "     - ENI $ID appears primary on $INST_ID; set FORCE_TERMINATE_INSTANCES=true to kill instance"
        fi
      fi
      continue
    fi
    if [[ "$IFTYPE" == "interface" && "$DESC" == *"VPC Endpoint"* ]]; then
      echo "     - ENI $ID looks like a VPC Endpoint ENI → re-running VPC endpoint deletion"
      VPCE_IDS="$(aws ec2 describe-vpc-endpoints --region "$AWS_REGION" \
        --filters Name=vpc-id,Values="$VPC_ID" --query 'VpcEndpoints[].VpcEndpointId' --output text || true)"
      [[ -n "$VPCE_IDS" ]] && aws ec2 delete-vpc-endpoints --region "$AWS_REGION" --vpc-endpoint-ids $VPCE_IDS || true
      continue
    fi
    echo "     - ENI $ID is $STATUS ($IFTYPE: $DESC) – will retry…"
  done
  echo "   waiting $SLEEP_SECS s for ENIs to settle…"; sleep "$SLEEP_SECS"
done

# Fix-B: Revoke SG references and delete SGs
echo "[Fix-B] Revoke SG references and delete non-default SGs…"
ALL_SGS="$(aws ec2 describe-security-groups --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query "SecurityGroups[?GroupName!='default'].GroupId" --output text || true)"

# (1) Revoke each SG's own ingress/egress rules
for SG in $ALL_SGS; do
  IN_JSON="$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$SG" \
    --query 'SecurityGroups[0].IpPermissions' --output json)"
  [[ "$(echo "$IN_JSON" | jq 'length')" -gt 0 ]] && \
    aws ec2 revoke-security-group-ingress --region "$AWS_REGION" --group-id "$SG" --ip-permissions "$IN_JSON" || true

  OUT_JSON="$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$SG" \
    --query 'SecurityGroups[0].IpPermissionsEgress' --output json)"
  [[ "$(echo "$OUT_JSON" | jq 'length')" -gt 0 ]] && \
    aws ec2 revoke-security-group-egress --region "$AWS_REGION" --group-id "$SG" --ip-permissions "$OUT_JSON" || true
done

# (2) Revoke rules in other SGs that reference these SGs
if [[ -n "$ALL_SGS" ]]; then
  REFS_JSON="$(printf '%s\n' $ALL_SGS | jq -R . | jq -s .)"
  CANDIDATES="$(aws ec2 describe-security-groups --region "$AWS_REGION" \
    --filters Name=vpc-id,Values="$VPC_ID" --output json)"
  echo "$CANDIDATES" | jq -c '.SecurityGroups[]' | while read -r ROW; do
    GID="$(echo "$ROW" | jq -r '.GroupId')"

    IN_REF="$(echo "$ROW" | jq --argjson refs "$REFS_JSON" \
      '{IpPermissions: [.IpPermissions[]? as $p |
        ($p.UserIdGroupPairs // []) as $pairs |
        if ($pairs | map(.GroupId) | inside($refs)) then $p else empty end ]}')"
    [[ "$(echo "$IN_REF" | jq '.IpPermissions | length')" -gt 0 ]] && \
      aws ec2 revoke-security-group-ingress --region "$AWS_REGION" \
        --group-id "$GID" --ip-permissions "$(echo "$IN_REF" | jq -c '.IpPermissions')" || true

    OUT_REF="$(echo "$ROW" | jq --argjson refs "$REFS_JSON" \
      '{IpPermissions: [.IpPermissionsEgress[]? as $p |
        ($p.UserIdGroupPairs // []) as $pairs |
        if ($pairs | map(.GroupId) | inside($refs)) then $p else empty end ]}')"
    [[ "$(echo "$OUT_REF" | jq '.IpPermissions | length')" -gt 0 ]] && \
      aws ec2 revoke-security-group-egress --region "$AWS_REGION" \
        --group-id "$GID" --ip-permissions "$(echo "$OUT_REF" | jq -c '.IpPermissions')" || true
  done
fi

# (3) One more ENI pass
echo "[Fix-B] Re-run ENI cleanup once more…"
ENI_IDS="$(aws ec2 describe-network-interfaces --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'NetworkInterfaces[].NetworkInterfaceId' --output text || true)"
if [[ -n "$ENI_IDS" ]]; then
  for eni in $ENI_IDS; do
    STATUS="$(aws ec2 describe-network-interfaces --region "$AWS_REGION" \
      --network-interface-ids "$eni" --query 'NetworkInterfaces[0].Status' --output text || true)"
    [[ "$STATUS" == "available" ]] && \
      aws ec2 delete-network-interface --region "$AWS_REGION" --network-interface-id "$eni" || true
  done
fi

# (4) Now delete non-default SGs
for SG in $ALL_SGS; do
  echo "   - delete SG $SG"
  aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$SG" || true
done

# 8) Disable mapPublicIpOnLaunch (best-effort)
echo "[8] Disabling mapPublicIpOnLaunch on public subnets…"
PUBS="$(aws ec2 describe-subnets --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" Name=tag:kubernetes.io/role/elb,Values=1 \
  --query 'Subnets[].SubnetId' --output text || true)"
for s in $PUBS; do
  aws ec2 modify-subnet-attribute --region "$AWS_REGION" --subnet-id "$s" --no-map-public-ip-on-launch || true
done

# 9) IGW
echo "[9] Detach & delete IGW (if any)…"
IGW_ID="$(aws ec2 describe-internet-gateways --region "$AWS_REGION" \
  --filters Name=attachment.vpc-id,Values="$VPC_ID" \
  --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || true)"
if [[ -n "$IGW_ID" && "$IGW_ID" != "None" ]]; then
  aws ec2 detach-internet-gateway --region "$AWS_REGION" --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" || true
  aws ec2 delete-internet-gateway  --region "$AWS_REGION" --internet-gateway-id "$IGW_ID" || true
else
  echo "   No IGW attached (ok)."
fi

# 10) Route tables
echo "[10] Deleting non-main route tables…"
RTBS="$(aws ec2 describe-route-tables --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'RouteTables[].{Id:RouteTableId,Assoc:Associations}' --output json)"
echo "$RTBS" | jq -c '.[]' | while read -r item; do
  RT_ID="$(echo "$item" | jq -r '.Id')"
  MAIN="$(echo "$item" | jq -r '.Assoc[]? | select(.Main==true) | .Main' || echo "")"
  if [[ "$MAIN" == "true" ]]; then
    echo "   - skipping main route table $RT_ID"
    continue
  fi
  ASSOC_IDS="$(echo "$item" | jq -r '.Assoc[]? | select(.Main!=true) | .RouteTableAssociationId')"
  for a in $ASSOC_IDS; do
    echo "   - disassociate $a"
    aws ec2 disassociate-route-table --region "$AWS_REGION" --association-id "$a" || true
  done
  echo "   - delete RTB $RT_ID"
  aws ec2 delete-route-table --region "$AWS_REGION" --route-table-id "$RT_ID" || true
done

# 11) NACLs
echo "[11] Deleting non-default NACLs…"
NACLS="$(aws ec2 describe-network-acls --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'NetworkAcls[?IsDefault==`false`].NetworkAclId' --output text || true)"
for n in $NACLS; do
  echo "   - delete NACL $n"
  aws ec2 delete-network-acl --region "$AWS_REGION" --network-acl-id "$n" || true
done

# 12) Subnets
echo "[12] Deleting Subnets…"
SUBNETS="$(aws ec2 describe-subnets --region "$AWS_REGION" \
  --filters Name=vpc-id,Values="$VPC_ID" \
  --query 'Subnets[].SubnetId' --output text || true)"
for subnet in $SUBNETS; do
  echo "   - delete subnet $subnet"
  aws ec2 delete-subnet --region "$AWS_REGION" --subnet-id "$subnet" || true
done

# 13) DHCP options
echo "[13] Reset & delete custom DHCP options (best-effort)…"
DOPT_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" --vpc-ids "$VPC_ID" \
  --query 'Vpcs[0].DhcpOptionsId' --output text 2>/dev/null || echo 'None')"
if [[ -n "$DOPT_ID" && "$DOPT_ID" != "default" && "$DOPT_ID" != "None" ]]; then
  echo "   VPC had DHCP options: $DOPT_ID"
  for V in $(aws ec2 describe-vpcs --region "$AWS_REGION" \
      --filters Name=dhcp-options-id,Values="$DOPT_ID" \
      --query 'Vpcs[].VpcId' --output text); do
    aws ec2 associate-dhcp-options --region "$AWS_REGION" --vpc-id "$V" --dhcp-options-id default || true
  done
  for _ in $(seq 1 12); do
    USING="$(aws ec2 describe-vpcs --region "$AWS_REGION" \
      --filters Name=dhcp-options-id,Values="$DOPT_ID" --query 'length(Vpcs)')"
    if [[ "$USING" == "0" ]]; then
      echo "   Deleting DHCP options $DOPT_ID"
      aws ec2 delete-dhcp-options --region "$AWS_REGION" --dhcp-options-id "$DOPT_ID" || true
      break
    fi
    echo "   DHCP options still associated; sleeping 10s…"; sleep 10
  done
else
  echo "   No custom DHCP options to clean (ok)."
fi

# FINAL: VPC
echo "[FINAL] Deleting VPC ${VPC_ID}…"
aws ec2 delete-vpc --region "$AWS_REGION" --vpc-id "$VPC_ID" || true
echo "[DONE] VPC ${VPC_ID} removal attempted. If it still fails with DependencyViolation, wait a minute and re-run."
