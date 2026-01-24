# GitOps (T2S Standard)

GitOps defines the desired state of environments (dev/staging/prod).
CI/CD produces artifacts (images); GitOps controls deployments.

Recommended tool: Argo CD (or Flux).

Structure:
- environments/dev
- environments/staging
- environments/prod
