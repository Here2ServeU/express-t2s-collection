# Okta SSO Integration Guide

## Purpose
This guide documents how SSO integrates with your Express Web App v7 and EKS workloads.

## Flow
1. User → Okta SSO Login  
2. Okta → Issues OIDC Token (ID + Access Token)  
3. EKS Ingress or App → Validates Token  
4. RBAC policies map groups → Access levels  

## Required Config:
- Client ID  
- Client Secret  
- Redirect URLs  
- Authorization URL  
- Token URL  
- JWKS endpoint  

## Kubernetes Integration
Configure `nginx-ingress` or `traefik` OIDC annotations:

```yaml
nginx.ingress.kubernetes.io/auth-url: "https://YOUR_OKTA_DOMAIN/oauth2/default/v1/authorize"
nginx.ingress.kubernetes.io/auth-response-headers: "x-forwarded-user"

---

# 4. **reliability-rbac-model.md**
Documentation for zero-trust RBAC for SRE operations.

```md
# Reliability RBAC Model

## Objective
Enforce identity-based access using Okta + Kubernetes RBAC.

## Roles:

### sre-admin
- Incident management
- Deployments
- SLO governance

### sre-operator
- Read logs/metrics
- Approve rollbacks
- Run chaos tests

### sre-auditor
- Observability dashboards
- SLO reports only

## Identity Mapping
Bind Okta groups to Kubernetes roles:

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: sre-admin-binding
roleRef:
  kind: ClusterRole
  name: sre-admin
subjects:
  - kind: Group
    name: okta-sre-admin

---

# ✔ Summary of All Security Scripts

| File | Type | Purpose |
|------|------|---------|
| **mfa-policy-setup.sh** | Script | Enforce MFA for production environments |
| **scim-provisioning.sh** | Script | Automate SCIM user provisioning/deprovisioning |
| **sso-integration-guide.md** | Guide | Document OIDC integration between Okta and app |
| **reliability-rbac-model.md** | Guide | Map Okta groups → K8s RBAC roles |

---

# Want these as a downloadable ZIP?
I can package: