terraform {
  required_version = ">= 1.8.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.54.1"
    }

    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.4.2"
    }
  }
  backend "s3" {
    # bucket = "terraform-state-$AWS_ACCOUNT_ID" # Não é permitido utilizar environment neste bloco. Estamos injetando no comando: terraform init -backend-config="bucket=terraform-state-${AWS_ACCOUNT_ID}"
    key    = "aws-playground/services/cloud-watch.tfstate"
    region = "us-east-1"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      managed-by = "terraform"
      repo       = "aws-playground/services/cloud-watch"
    }
  }
}
