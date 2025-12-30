#!/usr/bin/env bash
set -euo pipefail

ROLE_NAME="${1:-}"

if [[ -z "${ROLE_NAME}" ]]; then
  echo "Usage: bash $0 <ROLE_NAME>"
  exit 1
fi

echo "Cleaning role: ${ROLE_NAME}"

if ! aws iam get-role --role-name "${ROLE_NAME}" >/dev/null 2>&1; then
  echo "Role not found: ${ROLE_NAME}"
  exit 0
fi

echo "Detaching managed policies..."
ATTACHED=$(aws iam list-attached-role-policies --role-name "${ROLE_NAME}" --query "AttachedPolicies[].PolicyArn" --output text || true)
if [[ -n "${ATTACHED}" && "${ATTACHED}" != "None" ]]; then
  for arn in ${ATTACHED}; do
    aws iam detach-role-policy --role-name "${ROLE_NAME}" --policy-arn "${arn}"
  done
fi

echo "Deleting inline policies..."
INLINE=$(aws iam list-role-policies --role-name "${ROLE_NAME}" --query "PolicyNames[]" --output text || true)
if [[ -n "${INLINE}" && "${INLINE}" != "None" ]]; then
  for pname in ${INLINE}; do
    aws iam delete-role-policy --role-name "${ROLE_NAME}" --policy-name "${pname}"
  done
fi

echo "Removing from instance profiles (if any)..."
IPS=$(aws iam list-instance-profiles-for-role --role-name "${ROLE_NAME}" --query "InstanceProfiles[].InstanceProfileName" --output text || true)
if [[ -n "${IPS}" && "${IPS}" != "None" ]]; then
  for ip in ${IPS}; do
    aws iam remove-role-from-instance-profile --instance-profile-name "${ip}" --role-name "${ROLE_NAME}"
  done
fi

echo "Deleting role..."
aws iam delete-role --role-name "${ROLE_NAME}"

echo "Done."
