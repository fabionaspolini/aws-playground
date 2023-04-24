# detalhes sobre armazenamento gp3 https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

resource "aws_db_instance" "postgresql" {
  identifier             = "postgresql-sample" # nome do instância no painel aws
  db_name                = "sample"            # criar banco de dados (opcional)
  deletion_protection    = false               # impedir que instância seja deletada manualmente pelo console
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
  vpc_security_group_ids = [aws_security_group.rds_postgresql_sample.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  publicly_accessible    = true # autorizar acesso pela internet
  # iops                  = 3000 # padrão para discos menores de 400 gb
  # storage_throughput    = 125 #  padrão para discos menores de 400 gb

  performance_insights_enabled          = true # monitoramento
  performance_insights_retention_period = 7    # dias para armazenar histórico de monitoramento (7 dias free tier)
}

# Security Group + Rules

resource "aws_security_group" "rds_postgresql_sample" {
  name        = "rds-postgresql-sample"
  description = "Configuracoes do RDS postgresql-sample"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "rds-postgresql-sample"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgresql_sample_allow_vpc" {
  security_group_id = aws_security_group.rds_postgresql_sample.id
  description       = "Acesso ${data.aws_vpc.default.id}"
  ip_protocol       = "tcp"
  from_port         = 8455
  to_port           = 8455
  cidr_ipv4         = data.aws_vpc.default.cidr_block # liberar ips da vpc
  # cidr_ipv4 = "0.0.0.0/0" # liberar qualquer ip
  # security_group_id = data.aws_security_group.default.id # liberar baseado em segurity group
  tags = {
    Name = "${data.aws_vpc.default.id}"
  }
}


resource "aws_vpc_security_group_ingress_rule" "rds_postgresql_sample_allow_internet_access" {
  security_group_id = aws_security_group.rds_postgresql_sample.id
  description       = "Acesso publico internet"
  ip_protocol       = "tcp"
  from_port         = 8455
  to_port           = 8455
  cidr_ipv4         = "${data.http.ip.response_body}/32" # ip externo que pode conectar no db
  tags = {
    Name = "internet"
  }
}

# Secret Manager

resource "aws_secretsmanager_secret" "rds_postgresql_sample_username" {
  name = "rds-postgresql-sample-username"
}

resource "aws_secretsmanager_secret" "rds_postgresql_sample_password" {
  name = "rds-postgresql-sample-password"
}

resource "aws_secretsmanager_secret_version" "rds_postgresql_sample_username" {
  secret_id     = aws_secretsmanager_secret.rds_postgresql_sample_username.id
  secret_string = aws_rds_cluster.postgresql.master_username
}

resource "aws_secretsmanager_secret_version" "rds_postgresql_sample_password" {
  secret_id     = aws_secretsmanager_secret.rds_postgresql_sample_password.id
  secret_string = aws_rds_cluster.postgresql.master_password
}

# Parameter Store

resource "aws_ssm_parameter" "rds_postgresql_sample_endpoint" {
  name  = "rds-postgresql-sample-endpoint"
  type  = "String"
  value = aws_rds_cluster.postgresql.endpoint
}

resource "aws_ssm_parameter" "rds_postgresql_sample_reader_endpoint" {
  name  = "rds-postgresql-sample-reader-endpoint"
  type  = "String"
  value = aws_rds_cluster.postgresql.reader_endpoint
}

resource "aws_ssm_parameter" "rds_postgresql_sample_port" {
  name  = "rds-postgresql-sample-port"
  type  = "String"
  value = aws_rds_cluster.postgresql.port
}

resource "aws_ssm_parameter" "rds_postgresql_sample_database_name" {
  name  = "rds-postgresql-sample-database-name"
  type  = "String"
  value = aws_rds_cluster.postgresql.database_name
}
