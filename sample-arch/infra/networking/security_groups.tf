data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

# resource "aws_security_group" "rds_lambda_test" {
#   name        = "rds-lambda-test"
#   description = "Configuracoes do RDS lambda-test"
#   vpc_id      = data.aws_vpc.default.id

#   ingress {
#     description = "Acesso interno ${data.aws_vpc.default.id}"
#     from_port   = 8455
#     to_port     = 8455
#     protocol    = "tcp"
#     cidr_blocks = [data.aws_vpc.default.cidr_block] # liberar ips da vpc
#     # cidr_blocks = ["0.0.0.0/0"] # liberar qualquer ip
#     # security_groups = [data.aws_security_group.default.id] # liberar baseado em segurity group
#   }

#   ingress {
#     description = "Acesso publico internet"
#     from_port   = 8455
#     to_port     = 8455
#     protocol    = "tcp"
#     # cidr_blocks = [data.aws_vpc.default.cidr_block]
#     # cidr_blocks = ["0.0.0.0/0"]
#     cidr_blocks = ["${data.http.my_ip.response_body}/32"] # ip externo que pode conectar no db
#   }

#   tags = {
#     Name = "rds-lambda-test"
#   }
# }
