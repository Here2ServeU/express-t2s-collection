# Go / Okta / Terraform Micro-Cheat Sheet

## Go (Golang)

**Core Uses**
- Internal CLIs and automation tools.
- High-performance APIs and services.
- Concurrent workers and stream processors.

**Talking Points**
- “Use Go’s concurrency model (goroutines and channels) to build efficient internal tools.”
- “Build small, opinionated services in Go that handle reliability automation and platform tasks.”
- “Go’s static typing and single-binary deployment make it ideal for operational tooling.”

---

## Okta

**Core Capabilities**
- SSO for engineers and services.
- MFA enforcement for production access.
- SCIM-based user lifecycle management.
- Group-based RBAC for platform roles.

**Talking Points**
- “Integrate Okta with Kubernetes and CI/CD for controlled access to production.”
- “Enforce MFA and short-lived credentials to reduce blast radius.”
- “Use Okta groups mapped to Kubernetes roles to control who can do what in clusters.”

---

## Terraform

**Core Patterns**
- Modular, DRY infrastructure definitions.
- Terragrunt or similar to manage environments.
- Remote state (S3, Terraform Cloud, GCS) with locking.
- Policy-as-code (OPA, Checkov, Sentinel).

**Talking Points**
- “Design small, composable Terraform modules that teams can reuse.”
- “Wire Terraform into CI/CD with lint → plan → apply, including security and policy checks.”
- “Keep environment differences in configuration, not in duplicated code.”