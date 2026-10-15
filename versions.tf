terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "InnovaTech Solutions"
      Case        = "Case Study 2 - Week 5-8"
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Author      = "Emir Ozcan"
    }
  }
}
