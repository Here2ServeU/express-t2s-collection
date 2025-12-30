#!/usr/bin/env bash
set -euo pipefail

# delete_admin_bootstrap_role.sh
# Purpose: Safely delete the GitHub OIDC admin bootstrap role (break-glass).
# What it does:
#   1) Detaches any managed policies
#   2) Deletes any inline policies
#   3) Deletes the role
#
# Usage:
#   bash delete_admin_bootstrap_role.sh <ROLE_NAME>
#
# Example:
#   bash delete_admin_bootstrap_role.sh t2s-gha-admin-bootstrap
#
# Prereqs:
#   - AWS CLI configured with permissions to manage IAM
#   - jq is optional; this script does NOT require jq

ROLE_NAME="${1:-}"

if [[ -z "${ROLE_NAME}" ]]; then
  echo "ERROR: Missing ROLE_NAME"
  echo "Usage: bash $0 <ROLE_NAME>"
  exit 1
fi

echo "Starting cleanup for role: ${ROLE_NAME}"

# 0) Confirm role exists
if ! aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "Role does not exist: ${ROLE_NAME}"
  exit 0
fi

# 1) Detach all attached managed policies
echo "Detaching managed policies..."
ATTACHED_POLICY_ARNS=$(aws iam list-attached-role-policies \
  --role-name "${ROLE_NAME}" \
  --query "AttachedPolicies[].PolicyArn" \
  --output text || true)

if [[ -n "${ATTACHED_POLICY_ARNS}" && "${ATTACHED_POLICY_ARNS}" != "None" ]]; then
  for arn in ${ATTACHED_POLICY_ARNS}; do
    echo " - Detaching: ${arn}"
    aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${arn}"
  done
else
  echo " - No managed policies attached."
fi

# 2) Delete all inline policies
echo "Deleting inline policies..."
INLINE_POLICY_NAMES=$(aws iam list-role-policies \
  --role-name "${ROLE_NAME}" \
  --query "PolicyNames[]" \
  --output text || true)

if [[ -n "${INLINE_POLICY_NAMES}" && "${INLINE_POLICY_NAMES}" != "None" ]]; then
  for pname in ${INLINE_POLICY_NAMES}; do
    echo " - Deleting inline policy: ${pname}"
    aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name "${pname}"
  done
else
  echo " - No inline policies found."
fi

# 3) Remove instance profiles (rare, but can block delete)
echo "Checking instance profiles..."
INSTANCE_PROFILES=$(aws iam list-instance-profiles-for-role \
  --role-name "${ROLE_NAME}" \
  --query "InstanceProfiles[].InstanceProfileName" \
  --output text || true)

if [[ -n "${INSTANCE_PROFILES}" && "${INSTANCE_PROFILES}" != "None" ]]; then
  for ip in ${INSTANCE_PROFILES}; do
    echo " - Removing role from instance profile: ${ip}"
    aws iam remove-role-from-instance-profile \
      --instance-profile-name "${ip}" \
      --role-name "${ROLE_NAME}"
  done
else
  echo " - No instance profiles attached."
fi

# 4) Delete the role
echo "Deleting role..."
aws iam delete-role --role-name "${ROLE_NAME}"

# 5) Verify
if aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "WARNING: Role still exists (may be eventual consistency). Try again in 30 seconds."
  exit 2
else
  echo "SUCCESS: Role deleted: ${ROLE_NAME}"
fi
