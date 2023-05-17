# data "aws_ami" "ubuntu" {
#   most_recent = true

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }

#   owners = ["099720109477"] # Canonical
# }




# instâncias
# t4g.nano  | 2 vCPU x 0.5 gb ram - $ 0.0042 / hour - 10% spot = $ 2.76 month
# t3.nano   | 2 vCPU x 0.5 gb ram - $ 0.0052 / hour - 31% spot = $ 2.62 month
# t4g.micro | 2 vCPU x 1 gb ram   - $ 0.0084 / hour - 25% spot = $ 4.60 month
# t4g.small	| 2 vCPU x 2 gb ram   - $ 0.0168 / hour - 23% spot = $ 12.39 month
# t3.medium	| 2 vCPU x 3 gb ram   - $ 0.0416 / hour - 65% spot = $ 10.63 month

resource "aws_instance" "sample" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t4g.micro"
  subnet_id     = data.aws_subnet.zone_a.id
  key_name      = aws_key_pair.ec2_playground.key_name

  vpc_security_group_ids = [
    aws_security_group.allow_ssh_ingress_from_my_pc.id,
    aws_security_group.allow_internet_egress.id
  ]

  tags = {
    Name = "sample"
  }
}
