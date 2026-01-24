# Disaster Recovery Runbook (GCP)

## Objectives
- Restore critical user paths within RTO
- Limit data loss within RPO

## Steps (High-Level)
1. Declare incident and start communications
2. Validate scope (region, cluster, DB, networking)
3. Provision recovery environment (Terraform)
4. Restore/promote data stores
5. Shift traffic (DNS/Global LB)
6. Validate service health and SLO recovery

## Post-DR
- Post-incident review
- Update runbooks and automation to reduce RTO/RPO
