# T2S Golden Project Template

Official Transformed 2 Succeed (T2S) enterprise-grade template demonstrating:
- DevOps CI/CD (GitHub Actions)
- GitOps deployments (Argo CD-ready)
- Kubernetes orchestration
- Helm packaging
- SRE foundations: Observability, Reliability (SLOs), Chaos Engineering, AIOps, Security
- Day-2 Operations: runbooks, DR, on-call, checklists

## Required Delivery Flow
1) CI/CD builds/tests and produces container images
2) GitOps defines desired state for dev/staging/prod
3) Argo CD reconciles desired state to clusters
4) Helm is the standard packaging layer for Kubernetes workloads

## Getting Started
- Read: docs/overview.md
- Deploy via GitOps: gitops/environments/dev/application.yaml
- Run chaos tests: sre/chaos/
- Run AIOps scripts: sre/aiops/

## Student Handbook
See the PDF: T2S_Golden_Project_Student_Handbook.pdf (provided with the course distribution package)
