terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Local backend for initial setup
  # Can be migrated to S3 backend for production use
  backend "local" {
    path = "terraform.tfstate"
  }
}
