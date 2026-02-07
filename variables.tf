# AWS Region Configuration
variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

# AWS Account ID
variable "aws_account_id" {
  description = "AWS Account ID"
  type        = string
  default     = ""
}

# Environment Name
variable "environment" {
  description = "Environment name (e.g., dev, staging, production)"
  type        = string
  default     = "dev"
}

# Project Name
variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "event-driven-stack"
}
