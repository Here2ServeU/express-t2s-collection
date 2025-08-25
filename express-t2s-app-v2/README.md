
# Guide: Deploy Express App with Docker and Push to AWS ECR

This guide walks you through containerizing the Express app in **express-t2s-app-v2**, then pushing it to AWS Elastic Container Registry (ECR) using both a Bash script and a Python script.

---

## Prerequisites

Before starting, ensure you have:

- Docker installed and running
- AWS CLI configured (`aws configure`)
- An ECR repository created (e.g., `t2s-express-app`)
- Your AWS credentials ready

---

## Folder Structure

```
express-t2s-app-v2/
├── public/
├── scripts/
│   ├── push_to_ecr.sh
│   └── push_to_ecr.py
├── terraform/
├── Dockerfile
├── index.js
├── package.json
└── ...
```

---

## Step 1: Build the Docker Image

```bash
docker build -t t2s-express-app .
```

This command uses the `Dockerfile` to create a container image named `t2s-express-app`.

---

## Step 2: Run the Image Locally (Optional)

Test it locally before pushing:

```bash
docker run -p 3000:3000 t2s-express-app
```

Then open your browser at: [http://localhost:3000](http://localhost:3000)

---

## Step 3: Push Image to AWS ECR

### Option A: Use Bash Script

Navigate to the scripts folder and run:

```bash
cd scripts
bash push_to_ecr.sh
```

The script will:
- Authenticate Docker with ECR
- Tag the image with your AWS account ID
- Push the image to your ECR repository

Update the script with your real values:
```bash
AWS_ACCOUNT_ID=780593603882
REGION=us-east-1
REPO_NAME=t2s-express-app
IMAGE_TAG=latest
```

---

### Option B: Use Python Script

```bash
cd scripts
python3 push_to_ecr.py
```

This script uses `boto3` to:
- Authenticate
- Create the repository if it doesn't exist
- Tag and push your image

Make sure `boto3` is installed:
```bash
pip install boto3
```

---

## Step 4: Confirm in AWS Console

- Go to [ECR Console](https://console.aws.amazon.com/ecr)
- Open your repository (`t2s-express-app`)
- Confirm that the image appears with the `latest` tag

---

## Next Step

Move to **v3** (`express-t2s-app-v3`) to learn how to deploy this image to ECS using Terraform.

---

## Cleanup (Optional)

To remove the local Docker image and free up space:

```bash
docker rmi t2s-express-app
```

To remove all stopped containers:

```bash
docker container prune
```

To remove all unused Docker images:

```bash
docker image prune -a
```

To remove build cache:

```bash
docker builder prune
```

---

## Notes

- Your `terraform/` folder is reserved for infrastructure setup (ECS deployment in next version).
- This version is focused on containerization and ECR workflow.

---

© 2025 Emmanuel Naweji • Transformed 2 Succeed (T2S)
