# detalhes sobre armazenamento gp3 https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

resource "aws_db_instance" "default" {
  identifier             = "lambda-test" # nome do instância no painel aws
  db_name                = "lambda_test" # criar banco de dados (opcional)
  deletion_protection    = false         # impedir que instância seja deletada manualmente pelo console
  engine                 = "postgres"
  engine_version         = "15.2"
  port                   = 8455
  username               = "postgres"
  password               = "teste.123456"
  parameter_group_name   = "default.postgres15"
  instance_class         = "db.t4g.micro"
  storage_type           = "gp3" # general purpose SSD
  allocated_storage      = 20
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_lambda_test.id]
  publicly_accessible    = true # autorizar acesso pela internet
  # iops                  = 3000 # padrão para discos menores de 400 gb
  # storage_throughput    = 125 #  padrão para discos menores de 400 gb
  # db_subnet_group_name  =
}

resource "aws_security_group" "rds_lambda_test" {
  name        = "rds-lambda-test"
  description = "Configuracoes do RDS lambda-test"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Acesso publico internet"
    from_port   = 8455
    to_port     = 8455
    protocol    = "tcp"
    # cidr_blocks = [data.aws_vpc.main.cidr_block]
    # cidr_blocks = ["0.0.0.0/0"]
    cidr_blocks = ["${data.http.ip.response_body}/32"] # ip externo que pode conectar no db
  }

  ingress {
    description = "Acesso interno ${data.aws_vpc.main.id}"
    from_port   = 8455
    to_port     = 8455
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
    # cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-lambda-test"
  }
}
