#!/usr/bin/env bash
# Provision EKS + ALB controller using the terraform/eks module
# Run from the REPO ROOT: bash scripts/provision.sh
set -euo pipefail

# Resolve repo root (script may be called from anywhere)
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

EKS_DIR="$REPO_ROOT/terraform/eks"

if [[ ! -d "$EKS_DIR" ]]; then
  echo "ERROR: Expected directory $EKS_DIR not found."
  exit 1
fi

cd "$EKS_DIR"

# Sanity check: ensure there's at least one .tf file
if ! ls *.tf >/dev/null 2>&1; then
  echo "ERROR: No Terraform configuration files found in $EKS_DIR"
  exit 1
fi

echo ">>> terraform init ($EKS_DIR)"
terraform init -upgrade

echo ">>> terraform apply"
terraform apply -auto-approve

echo ">>> write kubeconfig"
REGION="$(terraform output -raw region)"
CLUSTER="$(terraform output -raw cluster_name)"
aws eks update-kubeconfig --name "$CLUSTER" --region "$REGION"

echo ">>> wait for ALB controller"
kubectl -n kube-system rollout status deploy/aws-load-balancer-controller

echo "SUCCESS: EKS ready. Region=$REGION Cluster=$CLUSTER"
