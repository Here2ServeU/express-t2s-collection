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

Update the script with your real values:
```bash
AWS_ACCOUNT_ID=780593603882
REGION=us-east-1
REPO_NAME=t2s-express-app
IMAGE_TAG=latest
```

---

### Option B: Use Python Script

1. Navigate to the scripts folder:

```bash
cd scripts
```

2. (Recommended) Set up a virtual environment:

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows use: venv\Scripts\activate
pip install boto3
```

3. Run the Python script:

```bash
python push_to_ecr.py
```

This script uses `boto3` to:
- Authenticate with AWS
- Create the repository if it doesn't exist
- Tag and push your Docker image

---

## Step 4: Confirm in AWS Console

- Go to [ECR Console](https://console.aws.amazon.com/ecr)
- Open your repository (`t2s-express-app`)
- Confirm that the image appears with the `latest` tag

---

## Step 5: Clean Up (Optional)

To clean up Docker resources locally:

```bash
# Stop all containers
docker stop $(docker ps -aq)

# Remove all containers
docker rm $(docker ps -aq)

# Remove all images (use with caution)
docker rmi $(docker images -q)
```

To deactivate and delete your virtual environment (optional):

```bash
deactivate
rm -rf venv
```

---

## Next Step

Move to **v3** (`express-t2s-app-v3`) to learn how to deploy this image to ECS using Terraform.

---

## Notes

- Your `terraform/` folder is reserved for infrastructure setup (ECS deployment in next version).
- This version is focused on containerization and ECR workflow.

---

© 2025 Emmanuel Naweji • Transformed 2 Succeed (T2S)
