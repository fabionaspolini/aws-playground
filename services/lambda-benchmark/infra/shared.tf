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

data "aws_subnet" "zone_a" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1a"
}

data "aws_subnet" "zone_b" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "us-east-1b"
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


resource "aws_eip" "lambda_samples" {
  vpc = true
  tags = {
    Name = "lambda-samples"
  }
}

resource "aws_nat_gateway" "lambda_samples" {
  allocation_id = aws_eip.lambda_samples.id
  subnet_id     = data.aws_subnet.zone_b.id

  tags = {
    Name = "lambda-samples"
  }
}


resource "aws_route_table" "lambda_samples" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lambda_samples.id
  }

  tags = {
    Name = "lambda-samples"
  }
}

resource "aws_route_table_association" "lambda_samples" {
  subnet_id      = data.aws_subnet.zone_a.id
  route_table_id = aws_route_table.lambda_samples.id
}