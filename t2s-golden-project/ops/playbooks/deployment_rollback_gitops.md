# Deployment Rollback (GitOps)

Roll back a Kubernetes deployment safely using GitOps.

## Trigger Conditions
- SLO burn rate exceeds threshold
- Error rate or latency regression after release
- Customer-impacting alerts firing

## Rollback Steps (Argo CD + Helm)
1. Identify last known good version (Git history of gitops/environments/<env>/values.yaml)
2. Roll back by Git revert (preferred) or set image tag to last good
3. Confirm Argo CD sync to Healthy + Synced
4. Validate recovery (SLOs, dashboards, smoke tests)

## Post-Rollback
- Create incident timeline
- Update docs/troubleshooting.md
- Add pipeline gates to prevent recurrence
