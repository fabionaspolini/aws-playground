terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.61"
    }
  }
  backend "s3" {
    bucket = "terraform-state-$AWS_ACCOUNT_ID"
    key    = "dynamodb"
    region = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      managed-by = "terraform"
    }
  }
}
