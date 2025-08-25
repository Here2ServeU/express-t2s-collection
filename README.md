
# Express T2S App Monorepo

## Overview

Welcome to the Express T2S App Monorepo, a structured collection of Node.js + Express applications designed to power the mission of **Transformed 2 Succeed (T2S)**.

Each versioned folder (v1, v2, v3, etc.) reflects a milestone in building a secure, scalable, and production-ready web platform using DevOps and Cloud best practices.

Our long-term goal is to deliver a mentorship and learning system that is:
- Dockerized for consistency across environments
- Cloud-deployed via Terraform (ECR, ECS, EKS on AWS)
- Secured with IAM, WAF, and DevSecOps scanning
- Observable with tools like Prometheus and Grafana
- Cost-aware through FinOps integration
- Automated with CI/CD, GitOps, and AI-enhanced monitoring

---

## Project Goals

This monorepo will help you:
- Build Docker images for each app version
- Push to Amazon ECR (Elastic Container Registry)
- Deploy using ECS and EKS with Terraform
- Automate CI/CD using GitHub Actions
- Integrate observability (Prometheus, Grafana, CloudWatch)
- Secure infrastructure using Trivy, Checkov, IAM, and WAF
- Optimize infrastructure costs using FinOps tools
- Add Site Reliability Engineering (SRE) best practices
- Incorporate AI for automated health checks and alerts

---

## Version Guide

| Version              | Description                                      |
|----------------------|--------------------------------------------------|
| express-t2s-app-v1   | Basic Node.js + Express application              |
| express-t2s-app-v2   | Docker containerization added                    |
| express-t2s-app-v3   | Deployed to AWS ECS + ECR via Terraform          |
| express-t2s-app-v4   | GitHub Actions CI/CD pipelines                   |
| express-t2s-app-v5   | Helm package manager support for EKS             |
| express-t2s-app-v6   | GitOps, monitoring, and observability stack      |
| express-t2s-app-v7   | DevSecOps: Policies, image scanning, IAM hardening |
| express-t2s-app-v8   | FinOps: Real-time cost insights                  |
| express-t2s-app-v9   | SRE tools: SLOs, alerting, dashboards            |
| express-t2s-app-v10  | AI integration: Self-healing and predictive automation |

---

## Repo Structure

```
express-t2s-app/
├── express-t2s-app-v1/      # Hello World + Node.js + Express
├── express-t2s-app-v2/      # Docker + Local Container
├── express-t2s-app-v3/      # Terraform + AWS ECS Deployment
├── express-t2s-app-v4/      # GitHub Actions CI/CD
├── express-t2s-app-v5/      # Helm + Kubernetes
├── express-t2s-app-v6/      # GitOps, Grafana, Prometheus
├── express-t2s-app-v7/      # DevSecOps: Trivy, Checkov, Kyverno
├── express-t2s-app-v8/      # FinOps Dashboard Integration
├── express-t2s-app-v9/      # Site Reliability Engineering
├── express-t2s-app-v10/     # AI Monitoring & Automation
└── README.md
```

---

## How to Use This Project

Each versioned subproject includes its own `guide.md` file with detailed instructions for:
- Building and testing the app
- Infrastructure deployment using Terraform
- CI/CD automation using GitHub Actions
- Kubernetes configuration (if applicable)
- Security and cost optimization

To begin working with a specific version:

```bash
# Navigate to the desired version folder
cd express-t2s-app/express-t2s-app-v3

# Open the detailed guide
code guide.md  # Or use any markdown viewer/editor
```

🛠️ Each version builds upon the previous one — feel free to explore them in order or jump to the one you need.

---

© 2025 Emmanuel Naweji. All rights reserved.  
This project is part of the Transformed 2 Succeed (T2S) infrastructure training ecosystem.
