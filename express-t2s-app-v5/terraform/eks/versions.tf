terraform {
  required_version = ">= 1.3.0"
  # To use S3 backend, replace this with your backend block.
  # backend "s3" {}
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.55" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.29" }
    helm       = { source = "hashicorp/helm", version = "~> 2.13" }
  }
}
