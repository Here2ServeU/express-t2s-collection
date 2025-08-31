module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 9.0"

  name               = "eks-cluster-alb"
  load_balancer_type = "application"
  vpc_id             = var.vpc_id
  subnets            = var.public_subnets
  internal           = false

  tags = {
    Name = "eks-cluster-alb"
  }
}
