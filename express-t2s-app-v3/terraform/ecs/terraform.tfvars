# Region
region = "us-east-1"

# Cluster / Service / Task
cluster_name  = "t2s-ecs-cluster"
service_name  = "t2s-express-service"
task_family   = "t2s-express-task"
task_cpu      = "256"
task_memory   = "512"
container_name = "t2s-container"
container_port = 3000
desired_count  = 1

# Image from your ECR repository
image_url = "Account_ID.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag = "latest"

# Networking (replace with your real IDs)
vpc_id     = "vpc-xxxxxxxxxxxxxxxxx"
subnet_ids = ["subnet-xxxxxxxxxxxx306", "subnet-xxxxxxxxxxxx234"]

# Security Group
sg_name        = "t2s-ecs-sg"
sg_description = "Allow HTTP to Express app"

# IAM
task_execution_role_name = "t2s-ecs-task-execution-role"
