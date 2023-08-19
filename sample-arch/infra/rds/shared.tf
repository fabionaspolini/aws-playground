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
    values = ["us-east-1a", "us-east-1b", "us-east-1c"]
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

resource "aws_db_subnet_group" "default" {
  name        = "sample-arch-playground"
  description = "sample-arch-playground"
  subnet_ids  = data.aws_subnets.deploy_zones.ids
}
