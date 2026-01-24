# Pre-Deployment Checklist (T2S)

## Change Readiness
- [ ] Change description + reason documented
- [ ] Rollback plan documented (ops/playbooks/deployment_rollback_gitops.md)

## CI/CD
- [ ] Build/tests pass
- [ ] Security scan executed (Trivy/Snyk/etc.)
- [ ] Artifact immutable (tag is SHA/version)

## SRE Gates
- [ ] SLOs defined for critical paths
- [ ] Dashboards reviewed
- [ ] Alert routes validated

## Dependencies
- [ ] DB, cache, queues healthy
- [ ] No capacity constraints expected

## GitOps
- [ ] GitOps PR created and reviewed
- [ ] Correct environment values selected
