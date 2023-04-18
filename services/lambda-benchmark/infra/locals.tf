locals {
  deploy_benchmark_basic_aot              = false
  deploy_benchmark_data_access_aot        = false
  deploy_benchmark_data_access_aot_dapper = true

  rds_address       = aws_db_instance.default.address
  rds_port          = aws_db_instance.default.port
  rds_username      = aws_db_instance.default.username
  rds_password      = aws_db_instance.default.password
  connection_string = "Server=${local.rds_address};Port=${local.rds_port};Database=lambda_test;User Id=${local.rds_username};Password=${local.rds_password}"
}
