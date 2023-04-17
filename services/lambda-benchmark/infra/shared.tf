locals {
  security_group_id = "sg-0fe89567949c742c3"
}

# Obter VPC padrão da account
data "aws_vpc" "main" {
  default = true
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1c"]
  }
}

# Obter IP público da máquina executando o terraform para liberar acesso externo no security group (Sua máquina)
data "http" "ip" {
  url = "https://ifconfig.me/ip"
}


# resource "aws_security_group" "allow_rds_lambda_test_access" {
#   name        = "allow-access-to-rds-lambda-test"
#   description = "Autorizar acesso ao RDS lambda-test"
#   vpc_id      = data.aws_vpc.main.id

#   ingress {
#     description = "Acesso publico internet"
#     from_port   = 8455
#     to_port     = 8455
#     protocol    = "tcp"
#     # cidr_blocks = [data.aws_vpc.main.cidr_block]
#     # cidr_blocks = ["0.0.0.0/0"]
#     cidr_blocks = ["189.28.181.215/32"] # ip externo que pode conectar no db
#   }

#   tags = {
#     Name = "allow-rds-lambda-test-access"
#   }
# }