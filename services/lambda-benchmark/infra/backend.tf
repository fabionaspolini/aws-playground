terraform {
  required_version = ">= 1.9.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.74.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.3.0"
    }
  }
  backend "s3" {
    # bucket = "terraform-state-$AWS_ACCOUNT_ID" # Não é permitido utilizar environment neste bloco. Estamos injetando no comando: terraform init -backend-config="bucket=terraform-state-${AWS_ACCOUNT_ID}"
    key    = "aws-playground/services/lambda-benchmark.tfstate"
    region = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      managed-by = "terraform"
      repo       = "aws-playground/services/lambda-benchmark"
    }
  }
}
