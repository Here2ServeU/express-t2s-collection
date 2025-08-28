provider "aws" {
  region = var.region
}

# After the EKS cluster is created, these providers will be configured
# using the cluster endpoint & auth (see data sources below).
