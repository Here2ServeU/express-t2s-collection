# Express T2S App – Full DevOps Guide (Beginner Friendly)

This project provides a comprehensive, hands-on walkthrough for building, containerizing, and deploying a Node.js Express application to AWS using industry-standard DevOps tools and automated best practices.

## Infrastructure Overview & Business Value

### 1. **Containerization ([Docker](app/Dockerfile))**

* **What it is**: A platform that packages an application and its entire runtime environment (dependencies, libraries, and configurations) into a single, immutable container.
* **Why use it**: It eliminates "dependency hell" by ensuring the app runs identically in development, testing, and production environments.
* **Business Value**: Accelerates development cycles and reduces server costs by allowing multiple isolated applications to run efficiently on shared hardware.

### 2. **Artifact Management ([AWS ECR](terraform/ecr))**

* **What it is**: A fully managed Docker container registry used to store, manage, and deploy container images securely.
* **Why use it**: It serves as the single source of truth for your application versions and integrates natively with AWS deployment services.
* **Business Value**: Ensures proprietary code is stored securely and is highly available for rapid deployment at any scale.

### 3. **Orchestration ([AWS ECS](terraform/ecs))**

* **What it is**: A scalable container orchestration service that manages the lifecycle of your Docker containers across a cluster.
* **Why use it**: It removes the need to manage individual virtual machines, handling scaling, health monitoring, and load balancing automatically.
* **Business Value**: Ensures high availability; if a container fails, ECS automatically restarts it, maintaining a seamless experience for users.

### 4. **Infrastructure as Code ([terraform))**

* **What it is**: A tool that allows you to define and provision your entire cloud infrastructure using declarative configuration files.
* **Why use it**: It makes infrastructure repeatable and version-controlled, allowing you to track exactly how your cloud environment has evolved.
* **Business Value**: Enables companies to deploy entire environments in minutes with zero human error, drastically reducing recovery time during disasters.

---

## Security Best Practice: Handling Sensitive Data

A core pillar of DevOps is ensuring that **secrets are never pushed to GitHub repositories**.

* **`.tfvars` files**: These local files contain sensitive environment-specific data (like DB passwords or AWS keys) and must remain local.
* **`.gitignore` Management**: Always ensure your [`.gitignore`](.gitignore)) file explicitly includes `*.tfvars` to prevent accidental exposure.
* **Secrets Management**: For production-grade security, use **AWS Secrets Manager** to inject credentials into your containers at runtime instead of hardcoding them.

---

## How to Provision the Full Infrastructure

Follow these phases in the exact order specified to deploy the full stack successfully.

### **Phase 1: Remote Backend Initialization**

Before managing main resources, we must set up the **Terraform Backend** (S3 and DynamoDB) to store our state files safely and enable state locking.

1. Navigate to `terraform/backend`.
2. Run `terraform init` and `terraform apply`.

### **Phase 2: Registry & Container Build**

Next, we create the secure storage for our application image.

1. Navigate to `terraform/ecr` and run `terraform apply`.
2. Run your local **[build and push script](https://github.com/Here2ServeU/express-t2s-app-v3/tree/main/scripts)** to build your [Docker image](app/Dockerfile) and upload it to the new repository.

### **Phase 3: Core Infrastructure Deployment**

Finally, we provision the network and compute resources.

1. Navigate to `terraform/ecs`.
2. Run `terraform apply`. This will set up your **VPC**, **Application Load Balancer (ALB)**, and **ECS Service**.

---

## About the Author

**Emmanuel Naweji** is a dedicated Cloud, DevOps, and AI Engineer passionate about simplifying complex cloud architectures and empowering engineers through hands-on education. With a focus on automation and security, he helps organizations build scalable, resilient systems.

**Website**: [emmanuelnaweji.com](https://www.emmanuelnaweji.com/)
**LinkedIn**: [linkedin.com/in/ready2assist](https://linkedin.com/in/ready2assist)
**YouTube**: [Emmanuel Services](https://www.youtube.com/@TechWithEmmanuel)
