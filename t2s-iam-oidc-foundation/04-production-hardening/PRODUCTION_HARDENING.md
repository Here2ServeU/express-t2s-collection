# Production Hardening — GitHub OIDC Roles (T2S)

## Delete the admin bootstrap role
If you created the admin role, delete it after verification:

```bash
bash 01-roles/delete_role_admin_bootstrap.sh t2s-gha-admin-bootstrap
```

## Restrict deployments
- Use GitHub Environments for prod with required reviewers
- Deploy prod from tags or release branches only

## Separate AWS accounts
Use separate AWS accounts for dev, staging, prod.

## Short session duration
Keep sessions short (15–60 minutes). Adjust in role settings if needed.

## Audit logging
Enable CloudTrail and GuardDuty.

## Two-role model for EKS
Consider:
- EKS provisioning role (Terraform creates cluster/VPC/IAM)
- EKS deploy-only role (kubectl/helm only)
