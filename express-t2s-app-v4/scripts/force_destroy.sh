#!/usr/bin/env bash
set -euo pipefail

# -------- Inputs / discovery --------
EKS_DIR="${EKS_DIR:-terraform/eks}"

AWS_REGION="${AWS_REGION:-$(terraform -chdir="$EKS_DIR" output -raw region 2>/dev/null || echo us-east-1)}"
CLUSTER_NAME="${CLUSTER_NAME:-$(terraform -chdir="$EKS_DIR" output -raw cluster_name 2>/dev/null || echo qs-eks)}"
VPC_ID="${VPC_ID:-$(terraform -chdir="$EKS_DIR" output -raw vpc_id 2>/dev/null || true)}"
[[ -z "${VPC_ID:-}" || "$VPC_ID" == "null" ]] && VPC_ID="$(aws ec2 describe-vpcs --region "$AWS_REGION" \
  --filters Name=tag:Name,Values="$CLUSTER_NAME" Name=isDefault,Values=false \
  --query 'Vpcs[0].VpcId' --output text 2>/dev/null || true)"

echo "Region=$AWS_REGION  Cluster=$CLUSTER_NAME  VPC=$VPC_ID"

# -------- Step 0: Stop k8s things recreating infra (idempotent) --------
helm -n ingress-nginx uninstall ingress-nginx || true
helm -n kube-system uninstall aws-load-balancer-controller || true
kubectl delete ns apps --ignore-not-found || true
kubectl get ingress -A -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}' 2>/dev/null \
 | while read -r ns name; do kubectl -n "$ns" delete ingress "$name" --ignore-not-found || true; done

# Remove k8s/helm resources from TF state so destroy won’t try to contact API
if [ -d "$EKS_DIR/.terraform" ] || [ -f "$EKS_DIR/main.tf" ]; then
  pushd "$EKS_DIR" >/dev/null
  for addr in $(terraform state list 2>/dev/null | egrep '^(helm_release|kubernetes_)' || true); do
    echo "terraform state rm $addr"
    terraform state rm "$addr" || true
  done
  popd >/dev/null
fi

# -------- Step 1: Tear down EKS via AWS CLI (faster, avoids provider timeouts) --------
echo "Deleting EKS nodegroups (if any)..."
for ng in $(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'nodegroups[]' --output text 2>/dev/null || true); do
  echo " - delete nodegroup $ng"
  aws eks delete-nodegroup --cluster-name "$CLUSTER_NAME" --nodegroup-name "$ng" --region "$AWS_REGION" || true
done

echo "Waiting for nodegroups to delete..."
for i in {1..60}; do
  left=$(aws eks list-nodegroups --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'length(nodegroups)' --output text 2>/dev/null || echo 0)
  [ "$left" = "0" ] && break
  echo "  nodegroups remaining: $left  ($i/60)"; sleep 10
done

echo "Deleting EKS fargate profiles (if any)..."
for fp in $(aws eks list-fargate-profiles --cluster-name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'fargateProfileNames[]' --output text 2>/dev/null || true); do
  echo " - delete fargate profile $fp"
  aws eks delete-fargate-profile --cluster-name "$CLUSTER_NAME" --fargate-profile-name "$fp" --region "$AWS_REGION" || true
done

echo "Delete EKS cluster (if exists)..."
aws eks delete-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" 2>/dev/null || true

echo "Wait for cluster deletion..."
for i in {1..60}; do
  st=$(aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" --query 'cluster.status' --output text 2>/dev/null || echo "MISSING")
  [ "$st" = "MISSING" ] && break
  echo "  cluster status: $st  ($i/60)"; sleep 10
done

# -------- Step 2: ELB/NLBs & Target Groups in VPC --------
if [[ -n "${VPC_ID:-}" && "$VPC_ID" != "None" ]]; then
  echo "Deleting ELBv2 load balancers in VPC $VPC_ID..."
  for lb in $(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
              --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text 2>/dev/null); do
    echo " - delete LB $lb"
    aws elbv2 delete-load-balancer --load-balancer-arn "$lb" --region "$AWS_REGION" || true
  done

  for i in {1..30}; do
    remain=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" \
             --query "length(LoadBalancers[?VpcId=='$VPC_ID'])" --output text 2>/dev/null || echo 0)
    [ "$remain" = "0" ] && break
    echo "  waiting for LBs to delete... ($i/30)"; sleep 10
  done

  echo "Deleting Target Groups in VPC..."
  for tg in $(aws elbv2 describe-target-groups --region "$AWS_REGION" \
            --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text 2>/dev/null); do
    echo " - delete TG $tg"
    aws elbv2 delete-target-group --region "$AWS_REGION" --target-group-arn "$tg" || true
  done

  # -------- Step 3: NAT GWs (and wait) --------
  echo "Deleting NAT Gateways..."
  for ngw in $(aws ec2 describe-nat-gateways --region "$AWS_REGION" --filter Name=vpc-id,Values="$VPC_ID" \
            --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null); do
    echo " - delete NAT $ngw"
    aws ec2 delete-nat-gateway --region "$AWS_REGION" --nat-gateway-id "$ngw" || true
  done

  for i in {1..60}; do
    count=$(aws ec2 describe-nat-gateways --region "$AWS_REGION" --filter Name=vpc-id,Values="$VPC_ID" \
           --query 'length(NatGateways[?State!=`deleted`])' --output text 2>/dev/null || echo 0)
    [ "$count" = "0" ] && break
    echo "  waiting for NAT GWs to delete... ($i/60)"; sleep 10
  done

  # -------- Step 4: VPC Endpoints, ENIs, EIPs --------
  echo "Deleting Interface VPC Endpoints..."
  for vpce in $(aws ec2 describe-vpc-endpoints --region "$AWS_REGION" \
              --filters Name=vpc-id,Values="$VPC_ID" --query 'VpcEndpoints[].VpcEndpointId' --output text 2>/dev/null); do
    echo " - delete VPC endpoint $vpce"
    aws ec2 delete-vpc-endpoints --region "$AWS_REGION" --vpc-endpoint-ids "$vpce" || true
  done

  echo "Deleting unattached ENIs..."
  for eni in $(aws ec2 describe-network-interfaces --region "$AWS_REGION" \
             --filters Name=vpc-id,Values="$VPC_ID" Name=status,Values=available \
             --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null); do
    echo " - delete ENI $eni"
    aws ec2 delete-network-interface --region "$AWS_REGION" --network-interface-id "$eni" || true
  done

  # -------- Step 5: IGW detach & delete; route tables; subnets --------
  IGW_ID=$(aws ec2 describe-internet-gateways --region "$AWS_REGION" \
           --filters Name=attachment.vpc-id,Values="$VPC_ID" \
           --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null || true)

  if [[ -n "${IGW_ID:-}" && "$IGW_ID" != "None" ]]; then
    echo "Detaching & deleting IGW $IGW_ID..."
    aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$AWS_REGION" || true
    sleep 5
    aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$AWS_REGION" || true
  fi

  echo "Disassociate & delete non-main route tables..."
  RTBS=$(aws ec2 describe-route-tables --region "$AWS_REGION" --filters Name=vpc-id,Values="$VPC_ID" \
        --query 'RouteTables[].{id:RouteTableId,assoc:Associations}' --output json)
  echo "$RTBS" | jq -r '.[] | select([.assoc[]?.Main]|contains([true])|not) | .assoc[]?.RouteTableAssociationId' 2>/dev/null \
   | while read -r assoc; do
      [[ -n "$assoc" ]] && aws ec2 disassociate-route-table --association-id "$assoc" --region "$AWS_REGION" || true
    done
  echo "$RTBS" | jq -r '.[] | select([.assoc[]?.Main]|contains([true])|not) | .id' 2>/dev/null \
   | while read -r rtb; do
      [[ -n "$rtb" ]] && aws ec2 delete-route-table --route-table-id "$rtb" --region "$AWS_REGION" || true
    done

  echo "Delete subnets..."
  for sn in $(aws ec2 describe-subnets --region "$AWS_REGION" --filters Name=vpc-id,Values="$VPC_ID" \
            --query 'Subnets[].SubnetId' --output text 2>/dev/null); do
    echo " - delete subnet $sn"
    aws ec2 delete-subnet --subnet-id "$sn" --region "$AWS_REGION" || true
  done

  echo "Delete security groups except default..."
  for sg in $(aws ec2 describe-security-groups --region "$AWS_REGION" --filters Name=vpc-id,Values="$VPC_ID" \
            --query 'SecurityGroups[?GroupName!=`default`].GroupId' --output text 2>/dev/null); do
    echo " - delete SG $sg"
    aws ec2 delete-security-group --group-id "$sg" --region "$AWS_REGION" || true
  done

  echo "Delete VPC..."
  aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$AWS_REGION" || true
fi

echo "CLI cleanup done."
