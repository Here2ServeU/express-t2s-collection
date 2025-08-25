# ────────────────────────────────
# 📁 terraform.tfvars (for testing existing VPC)
# ────────────────────────────────
create_vpc   = false
vpc_id       = "vpc-004194e2184e0d40d"
subnet_ids   = ["subnet-0acca018b1cc5f306", "subnet-0dcc65506b8690621"]
image_url    = "780593603882.dkr.ecr.us-east-1.amazonaws.com/t2s-express-app"
image_tag    = "latest"
