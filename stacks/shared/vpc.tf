# Obter VPC padrão da account
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "deploy_zones" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1c"]
  }
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.default.id
  name   = "default" # security group padrão da VPC possui o nome "default", mas exibe em branco no console aws.
}

# Obter IP público da máquina executando o terraform para liberar acesso externo no security group (Sua máquina)
data "http" "ip" {
  url = "https://ifconfig.me/ip"
}

data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket" "temporary_deployment" {
#   bucket = "lambda-temporary-deployment-${data.aws_caller_identity.current.account_id}"
# }

# resource "aws_s3_bucket_acl" "temporary_deployment" {
#   bucket = aws_s3_bucket.temporary_deployment.id
#   acl    = "private"
# }
