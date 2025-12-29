#!/usr/bin/env bash
set -euo pipefail

#
# cleanup.sh — Delete EKS Cluster + VPC + ALL Dependencies + Terraform State
# Fully automated, safe, aggressive cleanup for:
#   - Terraform resources in state
#   - EKS cluster + nodegroups + fargate profiles
#   - VPC (subnets, routes, IGWs, SGs, NATs, ELBs, ENIs, Endpoints)
#
# Requirements:
#   aws, jq, bash, optional terraform
#

need() { command -v "$1" >/dev/null 2>&1 || { echo "ERROR: '$1' is required"; exit 1; }; }
need aws
need jq

AWS_REGION="${AWS_REGION:-$(aws configure get region 2>/dev/null || echo 'us-east-1')}"
CLUSTER_NAME="${CLUSTER_NAME:-}"
VPC_ID="${VPC_ID:-}"
FORCE_TERMINATE_INSTANCES="${FORCE_TERMINATE_INSTANCES:-false}"

line() { printf '%s\n' "===================================================="; }

echo
line
echo "[START] Cleanup Script Running"
echo "  AWS_REGION = ${AWS_REGION}"
echo "  CLUSTER_NAME (provided) = ${CLUSTER_NAME:-<auto>}"
echo "  VPC_ID (provided)       = ${VPC_ID:-<auto>}"
line

# ------------------------------------------------------
# PART 1 — Detect EKS cluster and its VPC
# ------------------------------------------------------

if [[ -z "$CLUSTER_NAME" ]]; then
  echo "[INFO] Auto-detecting first EKS cluster in region..."
  CLUSTER_NAME="$(aws eks list-clusters --region "$AWS_REGION" --query 'clusters[0]' --output text 2>/dev/null || true)"
  [[ "$CLUSTER_NAME" == "None" ]] && CLUSTER_NAME=""
fi

if [[ -n "$CLUSTER_NAME" ]]; then
  echo "[INFO] Using EKS cluster: $CLUSTER_NAME"

  VPC_FROM_CLUSTER="$(aws eks describe-cluster \
    --region "$AWS_REGION" \
    --name "$CLUSTER_NAME" \
    --query 'cluster.resourcesVpcConfig.vpcId' \
    --output text 2>/dev/null || echo "")"

  if [[ -z "$VPC_ID" && -n "$VPC_FROM_CLUSTER" ]]; then
    VPC_ID="$VPC_FROM_CLUSTER"
    echo "[INFO] VPC detected from cluster: $VPC_ID"
  fi
fi

if [[ -z "$VPC_ID" ]]; then
  echo "[INFO] No VPC from cluster. Detecting default VPC..."
  VPC_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" \
             --filters Name=isDefault,Values=true \
             --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)"
  [[ "$VPC_ID" == "None" ]] && VPC_ID=""
fi

if [[ -z "$VPC_ID" ]]; then
  echo "ERROR: No VPC_ID found. Set VPC_ID=vpc-xxxx manually."
  exit 1
fi

line
echo "[SCOPE] Resources to clean:"
echo "  - Cluster: ${CLUSTER_NAME:-<none>}"
echo "  - VPC:     ${VPC_ID}"
line

# ------------------------------------------------------
# PART 1.5 — TERRAFORM STATE CLEANUP (BEFORE AWS CLEANUP)
# ------------------------------------------------------

echo
line
echo "[TF] Terraform State Cleanup (best-effort)"
line

if command -v terraform >/dev/null 2>&1; then
  # NOTE: run this script from the directory where terraform state lives
  TF_RESOURCES=(
    "helm_release.aws_load_balancer_controller"
    "helm_release.ingress_nginx"
    "helm_release.aiops"
    "helm_release.express_web_app"
    "kubernetes_namespace_v1.apps"
    "kubernetes_namespace_v1.monitoring"
    "kubernetes_namespace_v1.aiops"
    "kubernetes_namespace_v1.ingress_nginx"
    "aws_eks_cluster.eks"
    "aws_eks_node_group.nodegroup"
  )

  for RES in "${TF_RESOURCES[@]}"; do
    echo "   - removing state: $RES"
    terraform state rm "$RES" >/dev/null 2>&1 || true
  done

  echo "[TF] Terraform state cleanup complete."
else
  echo "[TF] Terraform not installed. Skipping state cleanup."
fi

# ------------------------------------------------------
# PART 2 — Delete EKS Cluster
# ------------------------------------------------------

delete_cluster() {
  local C="$1"

  echo
  line
  echo "[CLEANUP] Deleting EKS cluster: $C"
  line

  local status
  status="$(aws eks describe-cluster --region "$AWS_REGION" \
            --name "$C" --query 'cluster.status' --output text 2>/dev/null || true)"

  if [[ "$status" == "None" || -z "$status" ]]; then
    echo "[INFO] Cluster not found — skipping cluster delete."
    return
  fi

  # 1. delete nodegroups
  echo "[1] Deleting nodegroups…"
  local NGS
  NGS="$(aws eks list-nodegroups --region "$AWS_REGION" --cluster-name "$C" --query 'nodegroups' --output text || true)"
  for ng in $NGS; do
    echo "  - Deleting nodegroup: $ng"
    aws eks delete-nodegroup --region "$AWS_REGION" --cluster-name "$C" --nodegroup-name "$ng" >/dev/null 2>&1 || true
  done

  # 2. delete fargate profiles
  echo "[2] Deleting fargate profiles…"
  local FPS
  FPS="$(aws eks list-fargate-profiles --region "$AWS_REGION" --cluster-name "$C" --query 'fargateProfileNames' --output text || true)"
  for fp in $FPS; do
    echo "  - Deleting fargate profile: $fp"
    aws eks delete-fargate-profile --region "$AWS_REGION" --cluster-name "$C" --fargate-profile-name "$fp" >/dev/null 2>&1 || true
  done

  # 3. delete cluster
  echo "[3] Deleting EKS cluster…"
  aws eks delete-cluster --region "$AWS_REGION" --name "$C" >/dev/null 2>&1 || true

  echo "[WAIT] Allowing ENIs to detach (60s)…"
  sleep 60
}

[[ -n "$CLUSTER_NAME" ]] && delete_cluster "$CLUSTER_NAME"

# ------------------------------------------------------
# PART 3 — Delete VPC + ALL RESOURCES
# ------------------------------------------------------

delete_vpc() {
  local V="$1"

  echo
  line
  echo "[CLEANUP] Cleaning VPC: $V in $AWS_REGION"
  line

  # ---- 0: (optional) terminate EC2 instances in VPC ----
  if [[ "$FORCE_TERMINATE_INSTANCES" == "true" ]]; then
    echo "[0] Terminating EC2 instances in VPC…"
    local INSTANCES
    INSTANCES="$(aws ec2 describe-instances --region "$AWS_REGION" \
      --filters Name=vpc-id,Values="$V" Name=instance-state-name,Values=pending,running,stopping,stopped \
      --query 'Reservations[].Instances[].InstanceId' --output text 2>/dev/null || true)"
    if [[ -n "$INSTANCES" ]]; then
      echo "  - Terminating: $INSTANCES"
      aws ec2 terminate-instances --region "$AWS_REGION" --instance-ids $INSTANCES >/dev/null 2>&1 || true
      aws ec2 wait instance-terminated --region "$AWS_REGION" --instance-ids $INSTANCES >/dev/null 2>&1 || true
    else
      echo "  - No instances found."
    fi
  else
    echo "[0] Skipping EC2 termination (set FORCE_TERMINATE_INSTANCES=true to enable)."
  fi

  # ---- A: ELBv2 ----
  echo "[A] Deleting ALB/NLB..."
  local ARNS
  ARNS="$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
            --query "LoadBalancers[?VpcId=='$V'].LoadBalancerArn" --output text 2>/dev/null || true)"
  for arn in $ARNS; do
    echo "  - $arn"
    aws elbv2 delete-load-balancer --region "$AWS_REGION" --load-balancer-arn "$arn" >/dev/null 2>&1 || true
  done

  # ---- B: Classic ELBs ----
  echo "[B] Deleting Classic ELBs..."
  local CLBS
  CLBS="$(aws elb describe-load-balancers --region "$AWS_REGION" \
           --query 'LoadBalancerDescriptions[].LoadBalancerName' --output text 2>/dev/null || true)"
  for name in $CLBS; do
    echo "  - $name"
    aws elb delete-load-balancer --region "$AWS_REGION" --load-balancer-name "$name" >/dev/null 2>&1 || true
  done

  # ---- C: NAT + EIPs ----
  echo "[C] Deleting NAT Gateways…"
  local NGWS
  NGWS="$(aws ec2 describe-nat-gateways --region "$AWS_REGION" \
            --filter Name=vpc-id,Values="$V" \
            --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null || true)"

  local NAT_EIPS=()
  for ngw in $NGWS; do
    echo "  - NAT Gateway: $ngw"
    local ALLOCS
    ALLOCS="$(aws ec2 describe-nat-gateways --region "$AWS_REGION" --nat-gateway-ids "$ngw" \
                --query 'NatGateways[0].NatGatewayAddresses[].AllocationId' --output text 2>/dev/null || true)"
    for a in $ALLOCS; do
      [[ -n "$a" && "$a" != "None" ]] && NAT_EIPS+=("$a")
    done
    aws ec2 delete-nat-gateway --region "$AWS_REGION" --nat-gateway-id "$ngw" >/dev/null 2>&1 || true
  done

  if [[ "${#NAT_EIPS[@]}" -gt 0 ]]; then
    echo "[C2] Releasing EIPs…"
    for alloc in "${NAT_EIPS[@]}"; do
      aws ec2 release-address --region "$AWS_REGION" --allocation-id "$alloc" >/dev/null 2>&1 || true
    done
  fi

  # ---- D: VPC Endpoints ----
  echo "[D] Deleting VPC Endpoints…"
  local VPCE_IDS
  VPCE_IDS="$(aws ec2 describe-vpc-endpoints --region "$AWS_REGION" \
      --filters Name=vpc-id,Values="$V" \
      --query 'VpcEndpoints[].VpcEndpointId' --output text 2>/dev/null || true)"
  if [[ -n "$VPCE_IDS" ]]; then
    echo "  - $VPCE_IDS"
    aws ec2 delete-vpc-endpoints --region "$AWS_REGION" --vpc-endpoint-ids $VPCE_IDS >/dev/null 2>&1 || true
  else
    echo "  - None."
  fi

  # ---- E: Subnets ----
  echo "[E] Deleting Subnets…"
  local SUBNETS
  SUBNETS="$(aws ec2 describe-subnets --region "$AWS_REGION" \
              --filters Name=vpc-id,Values="$V" \
              --query 'Subnets[].SubnetId' --output text 2>/dev/null || true)"
  for s in $SUBNETS; do
    echo "  - $s"
    aws ec2 delete-subnet --region "$AWS_REGION" --subnet-id "$s" >/dev/null 2>&1 || true
  done

  # ---- F: Route tables ----
  echo "[F] Deleting non-main Route Tables…"
  local RTBS_JSON
  RTBS_JSON="$(aws ec2 describe-route-tables --region "$AWS_REGION" \
      --filters Name=vpc-id,Values="$V" \
      --output json 2>/dev/null || echo '{}')"

  echo "$RTBS_JSON" | jq -c '.RouteTables[]?' | while read -r item; do
    local RT_ID
    RT_ID="$(echo "$item" | jq -r '.RouteTableId')"
    local MAIN
    MAIN="$(echo "$item" | jq -r '.Associations[]? | select(.Main==true) | .Main' || echo "")"

    if [[ "$MAIN" == "true" ]]; then
      echo "  - Skipping main route table $RT_ID"
      continue
    fi

    local ASSOC_IDS
    ASSOC_IDS="$(echo "$item" | jq -r '.Associations[]? | select(.Main!=true) | .RouteTableAssociationId')"
    for a in $ASSOC_IDS; do
      echo "    - Disassociate $a"
      aws ec2 disassociate-route-table --region "$AWS_REGION" --association-id "$a" >/dev/null 2>&1 || true
    done

    echo "  - Deleting RTB $RT_ID"
    aws ec2 delete-route-table --region "$AWS_REGION" --route-table-id "$RT_ID" >/dev/null 2>&1 || true
  done

  # ---- G: Internet Gateway ----
  echo "[G] Detaching & Deleting IGW…"
  local IGW
  IGW="$(aws ec2 describe-internet-gateways --region "$AWS_REGION" \
           --filters Name=attachment.vpc-id,Values="$V" \
           --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || true)"
  if [[ -n "$IGW" && "$IGW" != "None" ]]; then
    echo "  - IGW: $IGW"
    aws ec2 detach-internet-gateway --region "$AWS_REGION" --internet-gateway-id "$IGW" --vpc-id "$V" >/dev/null 2>&1 || true
    aws ec2 delete-internet-gateway  --region "$AWS_REGION" --internet-gateway-id "$IGW" >/dev/null 2>&1 || true
  else
    echo "  - No IGW found."
  fi

  # ---- H: Security Groups ----
  echo "[H] Deleting non-default Security Groups…"
  local SGS
  SGS="$(aws ec2 describe-security-groups --region "$AWS_REGION" \
         --filters Name=vpc-id,Values="$V" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text 2>/dev/null || true)"

  for sg in $SGS; do
    echo "  - SG: $sg"
    # best-effort revoke first
    local IN_JSON OUT_JSON
    IN_JSON="$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$sg" \
      --query 'SecurityGroups[0].IpPermissions' --output json 2>/dev/null || echo '[]')"
    OUT_JSON="$(aws ec2 describe-security-groups --region "$AWS_REGION" --group-ids "$sg" \
      --query 'SecurityGroups[0].IpPermissionsEgress' --output json 2>/dev/null || echo '[]')"

    if [[ "$(echo "$IN_JSON"  | jq 'length')" -gt 0 ]]; then
      aws ec2 revoke-security-group-ingress --region "$AWS_REGION" --group-id "$sg" \
        --ip-permissions "$IN_JSON" >/dev/null 2>&1 || true
    fi
    if [[ "$(echo "$OUT_JSON" | jq 'length')" -gt 0 ]]; then
      aws ec2 revoke-security-group-egress --region "$AWS_REGION" --group-id "$sg" \
        --ip-permissions "$OUT_JSON" >/dev/null 2>&1 || true
    fi

    aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$sg" >/dev/null 2>&1 || true
  done

  # ---- I: ENIs ----
  echo "[I] Deleting remaining ENIs…"
  local ENIS
  ENIS="$(aws ec2 describe-network-interfaces --region "$AWS_REGION" \
      --filters Name=vpc-id,Values="$V" \
      --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null || true)"
  for eni in $ENIS; do
    echo "  - ENI: $eni"
    aws ec2 delete-network-interface --region "$AWS_REGION" --network-interface-id "$eni" >/dev/null 2>&1 || true
  done

  # ---- J: Final VPC delete ----
  echo "[J] Deleting VPC: $V..."
  aws ec2 delete-vpc --region "$AWS_REGION" --vpc-id "$V" >/dev/null 2>&1 || true

  echo "[DONE] VPC deletion attempted."
}

delete_vpc "$VPC_ID"

line
echo "[COMPLETE] Cleanup finished."
line