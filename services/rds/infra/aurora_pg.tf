# detalhes sobre armazenamento gp3 https://docs.aws.amazon.com/pt_br/AmazonRDS/latest/UserGuide/CHAP_Storage.html#gp3-storage

resource "aws_rds_cluster" "postgresql" {
  cluster_identifier      = "aurora-postgresql-sample"
  engine                  = "aurora-postgresql"
  engine_version          = "15.2"
  engine_mode             = "provisioned"
  port                    = 8455
  master_username         = "postgres"
  master_password         = "teste.123456"
  database_name           = "sample"
  backup_retention_period = 1
  preferred_backup_window = "01:00-02:00"
  skip_final_snapshot     = true
  deletion_protection     = false # proteção de exclusão da instância pelo console (desabilitar apenas para testes)
  vpc_security_group_ids  = [aws_security_group.aurora_postgresql_sample.id]
  db_subnet_group_name    = aws_db_subnet_group.default.name
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count               = 2
  identifier          = "aurora-postgresql-sample-${count.index}"
  cluster_identifier  = aws_rds_cluster.postgresql.id
  instance_class      = "db.t4g.medium"
  engine              = aws_rds_cluster.postgresql.engine
  engine_version      = aws_rds_cluster.postgresql.engine_version
  publicly_accessible = true # autorizar acesso pela internet
  apply_immediately   = true # forçar aplicar alterações que causam indisponibilidade agora (habilitar apenas para testes)
}

# Security group + rules: aurora-postgresql-sample

resource "aws_security_group" "aurora_postgresql_sample" {
  name        = "aurora-postgresql-sample"
  description = "Configuracoes do RDS lambda-test"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "aurora-postgresql-sample"
  }
}

resource "aws_vpc_security_group_ingress_rule" "aurora_postgresql_sample_allow_vpc" {
  security_group_id = aws_security_group.aurora_postgresql_sample.id
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


resource "aws_vpc_security_group_ingress_rule" "aurora_postgresql_sample_allow_internet_access" {
  security_group_id = aws_security_group.aurora_postgresql_sample.id
  description       = "Acesso publico internet"
  ip_protocol       = "tcp"
  from_port         = 8455
  to_port           = 8455
  cidr_ipv4         = "${data.http.ip.response_body}/32" # ip externo que pode conectar no db
  tags = {
    Name = "internet"
  }
}
