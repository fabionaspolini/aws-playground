resource "aws_iam_role" "benchmark_postgresql_python" {
  name = "benchmark-postgresql-python-lambda"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn,
    data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn,
    resource.aws_iam_policy.ManageNetworkInterface.arn
  ]
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish_benchmark_postgresql_python" {
  provisioner "local-exec" {
    working_dir = "../src/postgresql-python"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_benchmark_postgresql_python" {
  type        = "zip"
  source_dir = "../src/postgresql-python/publish"
  output_path = "./.temp/postgresql-python.zip"
  depends_on  = [null_resource.publish_benchmark_postgresql_python]
}

resource "aws_lambda_function" "benchmark_postgresql_python" {
  filename      = "./.temp/postgresql-python.zip"
  function_name = "benchmark-postgresql-python"
  role          = aws_iam_role.benchmark_postgresql_python.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_benchmark_postgresql_python.output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.deploy_zones.ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ConnectionString = "host=${local.rds_address} dbname=${local.rds_db_name} port=${local.rds_port} user=${local.rds_username} password=${local.rds_password}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark_postgresql_python]
}

resource "aws_cloudwatch_log_group" "benchmark_postgresql_python" {
  name              = "/aws/lambda/benchmark-postgresql-python"
  retention_in_days = 1
}
