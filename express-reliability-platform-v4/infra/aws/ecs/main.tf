terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
}
provider "aws" { region = var.aws_region }

module "network" { source = "./modules/network" name = var.name aws_region = var.aws_region }
module "ecs" {
  source         = "./modules/ecs"
  name           = var.name
  vpc_id         = module.network.vpc_id
  public_subnets = module.network.public_subnets
  aws_region     = var.aws_region
  node_image     = var.node_image
  flask_image    = var.flask_image
  node_port      = 3000
  flask_port     = 5000
}
