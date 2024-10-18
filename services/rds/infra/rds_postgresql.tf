# detalhes sobre armazenamento gp3 https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

resource "aws_db_instance" "postgresql" {
  count                  = local.rds_postgresql ? 1 : 0
  apply_immediately      = true                    # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
  identifier             = "postgresql-playground" # nome do instância no painel aws
  db_name                = "sample"                # criar banco de dados (opcional)
  deletion_protection    = false                   # impedir que instância seja deletada manualmente pelo console
  engine                 = "postgres"
  engine_version         = "16.4"
  port                   = 8455
  username               = "postgres"
  password               = "teste.123456"
  parameter_group_name   = "default.postgres16"
  instance_class         = "db.t4g.large" # # db.t4g.large, db.t4g.medium, db.t4g.small, db.t4g.micro
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_postgresql_playground[0].id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  publicly_accessible    = true # autorizar acesso pela internet

  storage_type           = "gp2"          # general purpose SSD
  allocated_storage      = 20
  max_allocated_storage  = 100
  storage_encrypted      = false # Importante ativar em ambiente real
  # iops                  = 3000 # padrão para discos menores de 400 gb
  # storage_throughput    = 125 #  padrão para discos menores de 400 gb

  performance_insights_enabled          = true # monitoramento
  performance_insights_retention_period = 7    # dias para armazenar histórico de monitoramento (7 dias free tier)

  maintenance_window      = "Mon:02:00-Mon:04:00"
  backup_window           = "00:00-02:00"
  backup_retention_period = 1
}

resource "aws_db_instance" "postgresql_replicas" {
  count                  = local.rds_postgresql && local.rds_postgresql_replicas ? 1 : 0
  apply_immediately      = true # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
  identifier             = "postgresql-playground-replica"
  replicate_source_db    = aws_db_instance.postgresql[0].identifier
  engine                 = "postgres"
  engine_version         = "16.4"
  port                   = 8455
  parameter_group_name   = "default.postgres16"
  instance_class         = "db.t4g.micro" # "db.t4g.medium"
  storage_type           = "gp3"          # general purpose SSD
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.rds_postgresql_playground[0].id]
  publicly_accessible    = true # autorizar acesso pela internet

  performance_insights_enabled          = true # monitoramento
  performance_insights_retention_period = 7    # dias para armazenar histórico de monitoramento (7 dias free tier)

  backup_retention_period = 0 # disable backups to create DB faster
}

# Security Group + Rules

resource "aws_security_group" "rds_postgresql_playground" {
  count       = local.rds_postgresql ? 1 : 0
  name        = "rds-postgresql-playground"
  description = "Configuracoes para RDS postgresql-playground"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "rds-postgresql-playground"
  }
}

resource "aws_vpc_security_group_ingress_rule" "rds_postgresql_playground_allow_vpc" {
  count             = local.rds_postgresql ? 1 : 0
  security_group_id = aws_security_group.rds_postgresql_playground[0].id
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


resource "aws_vpc_security_group_ingress_rule" "rds_postgresql_playground_allow_internet_access" {
  count             = local.rds_postgresql ? 1 : 0
  security_group_id = aws_security_group.rds_postgresql_playground[0].id
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

resource "aws_secretsmanager_secret" "rds_postgresql_playground_username" {
  count                   = local.rds_postgresql ? 1 : 0
  name                    = "rds-postgresql-playground-username"
  recovery_window_in_days = 0 # forçar exclusão sem periodo de retenção
}

resource "aws_secretsmanager_secret" "rds_postgresql_playground_password" {
  count                   = local.rds_postgresql ? 1 : 0
  name                    = "rds-postgresql-playground-password"
  recovery_window_in_days = 0 # forçar exclusão sem periodo de retenção
}

resource "aws_secretsmanager_secret_version" "rds_postgresql_playground_username" {
  count         = local.rds_postgresql ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rds_postgresql_playground_username[0].id
  secret_string = aws_db_instance.postgresql[0].username
}

resource "aws_secretsmanager_secret_version" "rds_postgresql_playground_password" {
  count         = local.rds_postgresql ? 1 : 0
  secret_id     = aws_secretsmanager_secret.rds_postgresql_playground_password[0].id
  secret_string = aws_db_instance.postgresql[0].password
}

# Parameter Store

resource "aws_ssm_parameter" "rds_postgresql_playground_endpoint" {
  count = local.rds_postgresql ? 1 : 0
  name  = "rds-postgresql-playground-endpoint"
  type  = "String"
  value = aws_db_instance.postgresql[0].endpoint
}

resource "aws_ssm_parameter" "rds_postgresql_playground_reader_endpoint" {
  count = local.rds_postgresql ? 1 : 0
  name  = "rds-postgresql-playground-reader-endpoint"
  type  = "String"
  value = local.rds_postgresql_replicas ? aws_db_instance.postgresql_replicas[0].endpoint : aws_db_instance.postgresql[0].endpoint
}

resource "aws_ssm_parameter" "rds_postgresql_playground_port" {
  count = local.rds_postgresql ? 1 : 0
  name  = "rds-postgresql-playground-port"
  type  = "String"
  value = aws_db_instance.postgresql[0].port
}

resource "aws_ssm_parameter" "rds_postgresql_playground_database_name" {
  count = local.rds_postgresql ? 1 : 0
  name  = "rds-postgresql-playground-database-name"
  type  = "String"
  value = aws_db_instance.postgresql[0].db_name
}
