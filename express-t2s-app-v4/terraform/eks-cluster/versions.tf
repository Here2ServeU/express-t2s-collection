terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.28.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.4.0"
    }
    random    = { source = "hashicorp/random", version = "~> 3.6" }
    local     = { source = "hashicorp/local", version = "~> 2.5" }
    null      = { source = "hashicorp/null", version = "~> 3.2" }
    cloudinit = { source = "hashicorp/cloudinit", version = "~> 2.3" }
  }
}

