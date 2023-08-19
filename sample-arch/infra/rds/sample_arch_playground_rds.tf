# detalhes sobre armazenamento gp3 https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

resource "aws_db_instance" "sample_arch_playground" {
  apply_immediately      = true                     # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
  identifier             = "sample-arch-playground" # nome do instância no painel aws
  db_name                = "sample"                 # criar banco de dados (opcional)
  deletion_protection    = false                    # impedir que instância seja deletada manualmente pelo console
  engine                 = "postgres"
  engine_version         = "15.2"
  port                   = 8455
  username               = "postgres"
  password               = "teste.123456"
  parameter_group_name   = "default.postgres15"
  instance_class         = "db.t4g.medium" # "db.t4g.micro / db.t4g.small / db.t4g.medium"
  storage_type           = "gp3"           # general purpose SSD
  allocated_storage      = 20
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_sample_arch_playground.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  publicly_accessible    = true # autorizar acesso pela internet
  # iops                   = 3000 # padrão para discos menores de 400 gb
  # storage_throughput     = 125  #  padrão para discos menores de 400 gb

  performance_insights_enabled          = true # monitoramento
  performance_insights_retention_period = 7    # dias para armazenar histórico de monitoramento (7 dias free tier)

  maintenance_window      = "Mon:02:00-Mon:04:00"
  backup_window           = "00:00-02:00"
  backup_retention_period = 1
}

# resource "aws_db_instance" "sample_arch_playground_replica" {
#   apply_immediately      = true # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
#   identifier             = "sample-arch-playground-replica"
#   replicate_source_db    = aws_db_instance.sample_arch_playground.identifier
#   engine                 = "postgres"
#   engine_version         = "15.2"
#   port                   = 8455
#   parameter_group_name   = "default.postgres15"
#   instance_class         = "db.t4g.medium" # "db.t4g.micro / db.t4g.small / db.t4g.medium"
#   storage_type           = "gp3"           # general purpose SSD
#   skip_final_snapshot    = true
#   vpc_security_group_ids = [aws_security_group.rds_sample_arch_playground.id]
#   publicly_accessible    = true # autorizar acesso pela internet

#   performance_insights_enabled          = true # monitoramento
#   performance_insights_retention_period = 7    # dias para armazenar histórico de monitoramento (7 dias free tier)
#   backup_retention_period               = 0    # disable backups to create DB faster
# }

# Security Group + Rules

resource "aws_security_group" "rds_sample_arch_playground" {
  name        = "rds/sample-arch-playground"
  description = "Configuracoes para RDS sample-arch-playground"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "rds/sample-arch-playground"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_sample_arch_playground_allow_vpc" {
  security_group_id = aws_security_group.rds_sample_arch_playground.id
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

resource "aws_vpc_security_group_ingress_rule" "rds_sample_arch_playground_allow_internet_access" {
  security_group_id = aws_security_group.rds_sample_arch_playground.id
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

resource "aws_secretsmanager_secret" "rds_sample_arch_playground_username" {
  name                    = "/rds/sample-arch-playground/username"
  recovery_window_in_days = 0 # forçar exclusão sem periodo de retenção
}

resource "aws_secretsmanager_secret" "rds_sample_arch_playground_password" {
  name                    = "/rds/sample-arch-playground/password"
  recovery_window_in_days = 0 # forçar exclusão sem periodo de retenção
}

resource "aws_secretsmanager_secret_version" "rds_sample_arch_playground_username" {
  secret_id     = aws_secretsmanager_secret.rds_sample_arch_playground_username.id
  secret_string = aws_db_instance.sample_arch_playground.username
}

resource "aws_secretsmanager_secret_version" "rds_sample_arch_playground_password" {
  secret_id     = aws_secretsmanager_secret.rds_sample_arch_playground_password.id
  secret_string = aws_db_instance.sample_arch_playground.password
}

# Parameter Store

resource "aws_ssm_parameter" "rds_sample_arch_playground_endpoint" {
  name  = "/rds/sample-arch-playground/endpoint"
  type  = "String"
  value = aws_db_instance.sample_arch_playground.endpoint
}

resource "aws_ssm_parameter" "rds_sample_arch_playground_reader_endpoint" {
  name  = "/rds/sample-arch-playground/reader-endpoint"
  type  = "String"
  value = aws_db_instance.sample_arch_playground.endpoint
}

resource "aws_ssm_parameter" "rds_sample_arch_playground_port" {
  name  = "/rds/sample-arch-playground/port"
  type  = "String"
  value = aws_db_instance.sample_arch_playground.port
}

resource "aws_ssm_parameter" "rds_sample_arch_playground_database_name" {
  name  = "/rds/sample-arch-playground/database-name"
  type  = "String"
  value = aws_db_instance.sample_arch_playground.db_name
}
