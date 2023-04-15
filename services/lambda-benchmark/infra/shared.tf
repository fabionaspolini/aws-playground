locals {
  vpc_id = "vpc-0bfbd64667b2cf5b3"
}

data "aws_vpc" "main" {
  id = local.vpc_id
}

resource "aws_security_group" "rds_lambda_test" {
  name        = "rds_lambda_test"
  description = "Allow TLS inbound traffic"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Acesso publico internet"
    from_port   = 8455
    to_port     = 8455
    protocol    = "tcp"
    # cidr_blocks = [data.aws_vpc.main.cidr_block]
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["189.28.181.215/32"]
  }

  tags = {
    Name = "rds_lambda_test"
  }
}
