# Production Hardening for GitHub OIDC Roles (Recommended)

Use these controls to make your OIDC setup production-like.

## 1) Restrict by repo AND branch (already enabled)
- Trust policy should include:
  - `repo:OWNER/REPO`
  - `ref:refs/heads/main` (or your prod branch)

## 2) Restrict by workflow file (recommended for prod)
GitHub OIDC includes claims such as `job_workflow_ref`.
You can restrict trust policy further to only allow a specific workflow file.

Example condition to add under `Condition`:

```json
"StringEquals": {
  "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
  "token.actions.githubusercontent.com:job_workflow_ref": "${WORKFLOW_REF}"
}
```

## 3) Use GitHub Environments for prod approvals
- Create a GitHub Environment named `prod`
- Require manual approval
- Only allow the prod workflow to run after approval

## 4) Short session duration
Set role `MaxSessionDuration` low (e.g., 3600 seconds).
Example:

```bash
aws iam update-role --role-name t2s-gha-deploy-prod --max-session-duration 3600
```

## 5) Separate accounts for prod
Best practice:
- Dev account
- Staging account
- Prod account
Each account has its own OIDC provider and roles.

## 6) CloudTrail + alerts
- Ensure CloudTrail is enabled
- Alert on:
  - `AssumeRoleWithWebIdentity`
  - IAM policy changes
  - Unexpected role assumptions

## 7) Break-glass admin role
- If you create `t2s-gha-admin-bootstrap`, delete it after bootstrap.
- If you must keep it, restrict it to:
  - One repo
  - One workflow
  - One branch
  - And require GitHub environment approvals

