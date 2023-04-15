locals {
  vpc_id = "vpc-0bfbd64667b2cf5b3"
  security_group_id = "sg-0fe89567949c742c3"
}

data "aws_vpc" "main" {
  id = local.vpc_id
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
  filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1c"]
  }
}

# data "aws_subnet" "a" {
#   vpc_id = local.vpc_id
#   filter {
#     name   = "availability-zone"
#     values = ["us-east-1a"]
#   }
# }

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
    cidr_blocks = ["189.28.181.215/32"] # ip externo que pode conectar no db
  }

  tags = {
    Name = "rds_lambda_test"
  }
}

resource "aws_iam_policy" "manage_network_interface" {
  name        = "ManageNetworkInterface"
  path        = "/lambda-benchmark/"
  description = "Permite que o recurso crie, liste e remova  interfaces de rede"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}
