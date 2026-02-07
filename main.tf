# AWS Provider Configuration
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "EventDrivenStack"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
