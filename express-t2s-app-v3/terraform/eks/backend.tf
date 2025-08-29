terraform {
  backend "s3" {
    bucket         = "emmanuel-tf-state-29082025"     # Replace with your real S3 bucket name
    key            = "eks/terraform.tfstate"          # Unique path for EKS state
    region         = "us-east-1"                      # Match your deployment region
    dynamodb_table = "terraform-locks"                #  Optional but recommended for locking
    encrypt        = true
  }
}
