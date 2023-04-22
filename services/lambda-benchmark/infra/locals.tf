locals {
  deploy_benchmark_basic_aot             = false
  deploy_benchmark_dapper-aot_aot        = false
  deploy_benchmark_ef_aot                = false
  deploy_benchmark_geral_aot             = false
  deploy_benchmark_npgsql_aot            = false
  deploy_benchmark_postgresql_dotnet_aot = false
  deploy_benchmark_refit_aot             = false

  rds_address       = aws_db_instance.default.address
  rds_port          = aws_db_instance.default.port
  rds_username      = aws_db_instance.default.username
  rds_password      = aws_db_instance.default.password
  rds_db_name       = aws_db_instance.default.db_name
  connection_string = "Server=${local.rds_address};Port=${local.rds_port};Database=${local.rds_db_name};User Id=${local.rds_username};Password=${local.rds_password}"
}
