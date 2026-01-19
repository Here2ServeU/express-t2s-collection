# Express Web App to Enterprise AIOps Curriculum

This repository provides a comprehensive, hands-on journey from local Node.js development to managing an enterprise-grade, AI-driven cloud platform. It mirrors architecture used by industry leaders like Netflix and Shopify.

## Curriculum Roadmap

### Phase 1: Foundations & Containerization

* **v1: Local Development**: Build a robust foundation using Node.js and Express.
* **v2: Docker & AWS Registry**: Package the app into an immutable container and push it to **AWS ECR**.

### Phase 2: Orchestration & Infrastructure as Code (IaC)

* **v3 & v4: Terraform Automation**: Use **Terraform** to provision AWS ECS, VPCs, and Load Balancers.
* **v5: Enterprise Kubernetes (EKS)**: Deploy a scalable cluster on **Amazon EKS** with an **AWS ALB Controller**.

### Phase 3: Modern Ops (AIOps, GitOps & FinOps)

* **v6: Enterprise Modernization**: Implement **ArgoCD** for GitOps, **Prometheus/Grafana** for observability, and custom **AIOps** engines for anomaly detection.
* **AIOps Demo**: Includes a specialized module for human-in-the-loop remediation via Slack.

---

## Foundational Setup: t2s-iam-oidc-foundation

This foundation establishes secure, production-style authentication between GitHub Actions and AWS using OpenID Connect (OIDC), eliminating long-lived access keys.

### Why OIDC?

* **No static keys to leak**: Credentials are short-lived and auditable.
* **Granular Control**: Access is restricted by specific repository and branch.

### Quick Start

1. **Create OIDC Provider**: Run `bash 00-oidc-provider/create_oidc_provider.sh`.
2. **Create Least-Privilege Roles**: Roles are available for both **ECS** and **EKS** pipelines.
3. **Configure Environment Variables**:
```bash
export AWS_REGION="us-east-1"
export AWS_ACCOUNT_ID="123456789012"
export GITHUB_ORG="Here2ServeU"
export GITHUB_REPO="express-t2s-collection"

```



### Relevant Links

* [GitHub Actions Snippets](https://www.google.com/search?q=https://github.com/Here2ServeU/express-t2s-collection/tree/main/t2s-iam-oidc-foundation/03-github-actions-snippets)
* [Production Hardening Guide](https://www.google.com/search?q=https://github.com/Here2ServeU/express-t2s-collection/blob/main/t2s-iam-oidc-foundation/04-production-hardening/PRODUCTION_HARDENING.md)
---
## Author

By Emmanuel Naweji, 2025  
**Cloud | DevOps | SRE | FinOps | AI Engineer**  
Helping businesses modernize infrastructure and guiding engineers into top 1% career paths through real-world projects and automation-first thinking.

![AWS Certified](https://img.shields.io/badge/AWS-Certified-blue?logo=amazonaws)
![Azure Solutions Architect](https://img.shields.io/badge/Azure-Solutions%20Architect-0078D4?logo=microsoftazure)
![CKA](https://img.shields.io/badge/Kubernetes-CKA-blue?logo=kubernetes)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![GitHub Actions](https://img.shields.io/badge/CI/CD-GitHub%20Actions-blue?logo=githubactions)
![GitLab CI](https://img.shields.io/badge/CI/CD-GitLab%20CI-FC6D26?logo=gitlab)
![Jenkins](https://img.shields.io/badge/CI/CD-Jenkins-D24939?logo=jenkins)
![Ansible](https://img.shields.io/badge/Automation-Ansible-red?logo=ansible)
![ArgoCD](https://img.shields.io/badge/GitOps-ArgoCD-orange?logo=argo)
![VMware](https://img.shields.io/badge/Virtualization-VMware-607078?logo=vmware)
![Linux](https://img.shields.io/badge/OS-Linux-black?logo=linux)
![FinOps](https://img.shields.io/badge/FinOps-Cost%20Optimization-green?logo=money)
![OpenAI](https://img.shields.io/badge/AI-OpenAI-ff9900?logo=openai)

---

## Connect with Me

- [LinkedIn](https://www.linkedin.com/in/ready2assist/)
- [GitHub](https://github.com/Here2ServeU)
- [Medium](https://medium.com/@here2serveyou)

---

## Book a Free Consultation
- If you want me to help you with DevOps/Cloud/AI skills. 
- If you want me to help modernize your cloud infrastructure, DevOps, or AI strategy.  
👉🏾 [Schedule a free 1:1 consultation](https://bit.ly/letus-meet)
