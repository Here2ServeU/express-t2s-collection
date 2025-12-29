# Reliability RBAC Model

This document describes how identity (Okta) maps into Kubernetes RBAC for SRE work.

## Roles

### sre-admin
- Full control over Kubernetes resources in production.
- Can approve and execute deployments.
- Can run chaos experiments and DR tests.

### sre-operator
- Read-only on cluster resources.
- Can trigger rollbacks and scale operations via approved mechanisms.
- Can run predefined chaos scenarios.

### sre-auditor
- Read-only access to observability and SLO dashboards.
- No access to modify infrastructure.

## Identity Integration

Map Okta groups to Kubernetes RBAC roles:

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sre-admin-binding
roleRef:
  kind: ClusterRole
  name: sre-admin
  apiGroup: rbac.authorization.k8s.io
subjects:
  - kind: Group
    name: okta-sre-admin
    apiGroup: rbac.authorization.k8s.io