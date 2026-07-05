terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "eu-west-1"
  profile = "tf-admin"

  # Default tags applied to every single resource Terraform creates
  default_tags {
    tags = {
      Project     = "Enterprise-DevSecOps-Portfolio"
      Environment = "Production"
      ManagedBy   = "Terraform"
      Owner       = "Aakash Nigam"
    }
  }
}