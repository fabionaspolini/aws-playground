# detalhes sobre armazenamento gp3 https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

resource "aws_rds_cluster" "aurora_mysql_serverless" {
  apply_immediately      = true # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
  count                  = local.aurora_mysql_serverless ? 1 : 0
  cluster_identifier     = "aurora-mysql-serverless-playground"
  engine                 = "aurora-mysql"
  engine_version         = "8.0.mysql_aurora.3.03.0"
  engine_mode            = "provisioned"
  port                   = 8455
  master_username        = "postgres"
  master_password        = "teste.123456"
  database_name          = "sample"
  skip_final_snapshot    = true
  deletion_protection    = false # proteção de exclusão da instância pelo console (desabilitar apenas para testes)
  vpc_security_group_ids = [aws_security_group.aurora_mysql_serverless_playground[0].id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
  storage_encrypted      = false # Importante ativar em ambiente real

  preferred_maintenance_window = "Mon:02:00-Mon:04:00"
  preferred_backup_window      = "00:00-02:00"
  backup_retention_period      = 1

  allow_major_version_upgrade = true # autorizar atualização de versões majors

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 3.0
  }
}

resource "aws_rds_cluster_instance" "aurora_mysql_serverless" {
  count               = local.aurora_mysql_serverless ? 2 : 0
  apply_immediately   = true # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
  identifier          = "aurora-mysql-serverless-playground-${count.index}"
  cluster_identifier  = aws_rds_cluster.aurora_mysql_serverless[0].id
  instance_class      = "db.serverless"
  engine              = aws_rds_cluster.aurora_mysql_serverless[0].engine
  engine_version      = aws_rds_cluster.aurora_mysql_serverless[0].engine_version
  publicly_accessible = true # autorizar acesso pela internet

  performance_insights_enabled          = true # monitoramento
  performance_insights_retention_period = 7    # dias para armazenar histórico de monitoramento (7 dias free tier)
}

# Security Group + Rules

resource "aws_security_group" "aurora_mysql_serverless_playground" {
  count       = local.aurora_mysql_serverless ? 1 : 0
  name        = "aurora-mysql-serverless-playground"
  description = "Configuracoes para RDS aurora-mysql-serverless-playground"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "aurora-mysql-serverless-playground"
  }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_mysql_serverless_playground_allow_vpc" {
  count             = local.aurora_mysql_serverless ? 1 : 0
  security_group_id = aws_security_group.aurora_mysql_serverless_playground[0].id
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


resource "aws_vpc_security_group_ingress_rule" "aurora_mysql_serverless_playground_allow_internet_access" {
  count             = local.aurora_mysql_serverless ? 1 : 0
  security_group_id = aws_security_group.aurora_mysql_serverless_playground[0].id
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

resource "aws_secretsmanager_secret" "aurora_mysql_serverless_playground_username" {
  count                   = local.aurora_mysql_serverless ? 1 : 0
  name                    = "aurora-mysql-serverless-playground-username"
  recovery_window_in_days = 0 # forçar exclusão sem periodo de retenção
}

resource "aws_secretsmanager_secret" "aurora_mysql_serverless_playground_password" {
  count                   = local.aurora_mysql_serverless ? 1 : 0
  name                    = "aurora-mysql-serverless-playground-password"
  recovery_window_in_days = 0 # forçar exclusão sem periodo de retenção
}

resource "aws_secretsmanager_secret_version" "aurora_mysql_serverless_playground_username" {
  count         = local.aurora_mysql_serverless ? 1 : 0
  secret_id     = aws_secretsmanager_secret.aurora_mysql_serverless_playground_username[0].id
  secret_string = aws_rds_cluster.aurora_mysql_serverless[0].master_username
}

resource "aws_secretsmanager_secret_version" "aurora_mysql_serverless_playground_password" {
  count         = local.aurora_mysql_serverless ? 1 : 0
  secret_id     = aws_secretsmanager_secret.aurora_mysql_serverless_playground_password[0].id
  secret_string = aws_rds_cluster.aurora_mysql_serverless[0].master_password
}

# Parameter Store

resource "aws_ssm_parameter" "aurora_mysql_serverless_playground_endpoint" {
  count = local.aurora_mysql_serverless ? 1 : 0
  name  = "aurora-mysql-serverless-playground-endpoint"
  type  = "String"
  value = aws_rds_cluster.aurora_mysql_serverless[0].endpoint
}

resource "aws_ssm_parameter" "aurora_mysql_serverless_playground_reader_endpoint" {
  count = local.aurora_mysql_serverless ? 1 : 0
  name  = "aurora-mysql-serverless-playground-reader-endpoint"
  type  = "String"
  value = aws_rds_cluster.aurora_mysql_serverless[0].reader_endpoint
}

resource "aws_ssm_parameter" "aurora_mysql_serverless_playground_port" {
  count = local.aurora_mysql_serverless ? 1 : 0
  name  = "aurora-mysql-serverless-playground-port"
  type  = "String"
  value = aws_rds_cluster.aurora_mysql_serverless[0].port
}

resource "aws_ssm_parameter" "aurora_mysql_serverless_playground_database_name" {
  count = local.aurora_mysql_serverless ? 1 : 0
  name  = "aurora-mysql-serverless-playground-database-name"
  type  = "String"
  value = aws_rds_cluster.aurora_mysql_serverless[0].database_name
}
