import boto3
import subprocess

repo_name = "t2s-express-app"
region = "us-east-1"
image_tag = "latest"

ecr = boto3.client('ecr', region_name=region)
sts = boto3.client('sts')
account_id = sts.get_caller_identity()["Account"]
repo_uri = f"{account_id}.dkr.ecr.{region}.amazonaws.com/{repo_name}"

try:
    ecr.describe_repositories(repositoryNames=[repo_name])
except ecr.exceptions.RepositoryNotFoundException:
    ecr.create_repository(repositoryName=repo_name)

subprocess.run(f"aws ecr get-login-password --region {region} | docker login --username AWS --password-stdin {repo_uri}", shell=True, check=True)
subprocess.run(f"docker build -t {repo_name} .", shell=True, check=True)
subprocess.run(f"docker tag {repo_name}:{image_tag} {repo_uri}:{image_tag}", shell=True, check=True)
subprocess.run(f"docker push {repo_uri}:{image_tag}", shell=True, check=True)
