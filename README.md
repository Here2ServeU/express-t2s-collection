# Express T2S App Monorepo

## Overview (Situation)

This repository serves as the monorepo for the evolving Express-based web applications that power the mission of **Transformed 2 Succeed (T2S)**. Each version (`v1`, `v2`, etc.) represents a progressive iteration of the Node.js + Express app as we move from MVP to a production-grade, cloud-native, DevOps-enabled platform.

Our long-term vision is to create a mentorship system that is:
- Containerized using Docker
- Deployable to AWS (ECR, ECS, EKS)
- Monitored and observable
- Secured with IAM and DevSecOps practices
- Scalable, cost-efficient, and reliable

---

## Goals (Task)

- Containerize each app version with Docker
- Push container images to AWS ECR
- Deploy via ECS Fargate, then migrate to EKS
- Implement CI/CD using GitHub Actions
- Add observability and monitoring (Grafana, Prometheus, X-Ray)
- Enable DevSecOps scanning (Trivy, Checkov)
- Support authentication, email notifications, and mentorship automation

---

## Features Implemented (Action)

Each version directory (e.g. `express-t2s-app-v1`) includes:

- Node.js + Express backend server
- Public static asset folder and HTML signup form
- Git integration with branching and version tracking
- CI/CD-ready project structure with Docker support

---

## Run Locally

```bash
cd express-t2s-app-v1  # or any version
npm install
node index.js
```

Visit: http://localhost:3000

---

## Action Plan (What’s Next)

### Phase 1: Containerization & CI/CD
- Create Dockerfile & .dockerignore for each version
- Push images to ECR
- Build GitHub Actions workflows

### Phase 2: AWS ECS Deployment
- Set up ECS with Fargate + Load Balancer
- Enable HTTPS + Route 53 domain

### Phase 3: EKS + GitOps
- Create EKS with Terraform
- Use Helm + ArgoCD for Kubernetes deployments

### Phase 4: DevSecOps & IAM
- Trivy + Checkov integration
- Use AWS WAF, IAM, and Secrets Manager

### Phase 5: Observability
- Prometheus & Grafana Dashboards
- CloudWatch Logs and AWS X-Ray

### Phase 6: Mentorship Automation
- Log mentee form data
- Send emails on signup
- Store submissions securely

---

## Repo Structure

```
express-t2s-app/
├── express-t2s-app-v1/      
│   ├── public/
│   └── index.js
│
├── express-t2s-app-v2/      
│   ├── Dockerfile
│   └── .dockerignore
│
├── express-t2s-app-v3/      
│   └── .github/workflows/ci.yml
│
├── express-t2s-app-v4/      
│   ├── helm-chart/
│   └── terraform/
│
├── express-t2s-app-v5/      
│   ├── trivy-reports/
│   ├── checkov-config/
│   ├── prometheus/
│   ├── grafana/
│   └── argo-cd/
│
├── .gitignore
└── README.md
```

---

## Outcome (Result)

By the end of this project, we’ll have a DevOps-powered, production-grade platform supporting:
- CI/CD & GitOps
- Secure, observable infrastructure
- Containerized, scalable deployments
- Automated mentorship onboarding

---

## Local Deployment Steps

1. Clone the repository:
```bash
git clone git@github.com:Here2ServeU/express-t2s-app.git
cd express-t2s-app/express-t2s-app-v1
```

2. Install dependencies:
```bash
npm install
```

3. Start the application:
```bash
node index.js
```

4. Open your browser at:
```
http://localhost:3000
```

---

## World-Case Scenario Deployment (Cloud)

1. Build Docker image:
```bash
docker build -t t2s-web:v1 .
```

2. Authenticate with AWS:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
```

3. Tag & push image to ECR:
```bash
docker tag t2s-web:v1 <your-ecr-repo-uri>:v1
docker push <your-ecr-repo-uri>:v1
```

4. Deploy on ECS or EKS using Terraform and Helm (in v3–v5 folders)

5. Monitor via:
   - AWS CloudWatch
   - Grafana dashboards
   - AWS X-Ray traces

6. Trigger CI/CD via GitHub Actions

7. Onboard mentees automatically through form + email integration

---

© 2025 Emmanuel Naweji. All rights reserved.

