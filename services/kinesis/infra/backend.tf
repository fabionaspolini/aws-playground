terraform {
  required_version = ">= 1.8.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.49"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "2.4.2"
    }
  }
  backend "s3" {
    # Não é permitido utilizar environment variable neste bloco.
    # Iremos injetar como argumento da cli: terraform init -backend-config="bucket=terraform-state-${AWS_ACCOUNT_ID}"
    # bucket = "terraform-state-$AWS_ACCOUNT_ID"
    key    = "aws-playground/services/kinesis.tfstate"
    region = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      managed-by = "terraform"
      repo       = "aws-playground/services/kinesis"
    }
  }
}
