terraform {
  backend "s3" {
    bucket = "t2s-terraform-states"
    key    = "eks-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}
