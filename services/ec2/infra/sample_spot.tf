# instâncias
# t4g.nano  | 2 vCPU x 0.5 gb ram - $ 0.0042 / hour - 10% spot = $ 2.76 month
# t3.nano   | 2 vCPU x 0.5 gb ram - $ 0.0052 / hour - 31% spot = $ 2.62 month
# t4g.micro | 2 vCPU x 1 gb ram   - $ 0.0084 / hour - 25% spot = $ 4.60 month
# t4g.small	| 2 vCPU x 2 gb ram   - $ 0.0168 / hour - 23% spot = $ 12.39 month
# t3.medium	| 2 vCPU x 3 gb ram   - $ 0.0416 / hour - 65% spot = $ 10.63 month

# "aws_spot_instance_request" suporta todos os atributos de "aws_instance"
# Solicitando máquina spot sem subnet/zona para aumentar a chance de conseguir. A VPC é selecionada pelo VPC security group id
resource "aws_spot_instance_request" "sample_spot" {
  count         = local.sample_spot ? 1 : 0
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.micro"
  key_name      = aws_key_pair.ec2_playground.key_name
  spot_type     = "one-time" # one-time: encerrar solicitação de spot após término da instância. persistent (default): manter requisição aberta e subir nova máquina
  # spot_price    = "0.009" # preço máximo para pagar (opcional)

  vpc_security_group_ids = [
    data.aws_security_group.default.id,
    aws_security_group.allow_ssh_ingress_from_my_pc.id
  ]

  tags = {
    Name = "sample-spot"
  }
}
