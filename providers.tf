terraform {
  required_version = ">= 1.6.1"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.21"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = var.project
      Environment = local.environment
      Function    = "finops"
    }
  }
}
