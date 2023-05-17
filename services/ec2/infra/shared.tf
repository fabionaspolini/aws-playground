data "aws_caller_identity" "current" {}

# Obter VPC padrão da account
data "aws_vpc" "default" {
  default = true
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

# Imagem ubuntu 20.04 arm64
data "aws_ami" "ubuntu" {
  filter {
    name   = "image-id"
    values = ["ami-004811053d831c2c2"]
  }
}

# Chave SSH
data "tls_public_key" "ec2_playground" {
  private_key_openssh = file("~/.ssh/aws/ec2-playground")
}

resource "aws_key_pair" "ec2_playground" {
  key_name   = "ec2-playground"
  public_key = data.tls_public_key.ec2_playground.public_key_openssh
}

# Security Group + Rules - SSH ingress
resource "aws_security_group" "allow_ssh_ingress_from_my_pc" {
  name        = "allow-ssh-ingress-from-my-pc-playground"
  description = "Habilitar acesso SSH"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "allow-ssh-ingress-from-my-pc-playground"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress_from_my_pc" {
  security_group_id = aws_security_group.allow_ssh_ingress_from_my_pc.id
  description       = "Acesso SSH pela internet a partir do meu computador"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = "${data.http.ip.response_body}/32" # ip externo que pode conectar no db
  tags = {
    Name = "ssh-from-my-pc"
  }
}
