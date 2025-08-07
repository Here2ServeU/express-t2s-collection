# Region
region = "us-east-1"

# Cluster / Service / Task
cluster_name   = "t2s-ecs-cluster"
service_name   = "t2s-express-service"
task_family    = "t2s-express-task"
task_cpu       = "256"
task_memory    = "512"
container_name = "t2s-container"
container_port = 3000
desired_count  = 2

# Image from your ECR repository (no tag in image_url)
image_url = "780593603882.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag = "latest"

# Networking (replace with your real IDs)
vpc_id     = "vpc-0abc123456789def0"
subnet_ids = ["subnet-0123abcd4567efgh1", "subnet-0897abcd6543efgh2"]

# Security Group
sg_name        = "t2s-ecs-sg"
sg_description = "Allow HTTP to Express app via ALB"

# IAM
task_execution_role_name = "t2s-ecs-task-execution-role"
# task_execution_policy_arn uses default

# ALB
alb_name          = "t2s-express-alb"
alb_internal      = false
alb_listener_port = 80
health_check_path = "/"
target_group_name = "t2s-express-tg"

# Optional HTTPS (uncomment and set if you want TLS)
# enable_https   = true
# certificate_arn = "arn:aws:acm:us-east-1:780593603882:certificate/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
