resource "aws_iam_role" "benchmark_postgresql_nodejs" {
  name = "benchmark-postgresql-nodejs-lambda"

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
resource "null_resource" "publish_benchmark_postgresql_nodejs" {
  provisioner "local-exec" {
    working_dir = "../src/postgresql-nodejs"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_benchmark_postgresql_nodejs" {
  type        = "zip"
  source_dir = "../src/postgresql-nodejs"
  output_path = "./.temp/postgresql-nodejs.zip"
  depends_on  = [null_resource.publish_benchmark_postgresql_nodejs]
}

resource "aws_lambda_function" "benchmark_postgresql_nodejs" {
  filename      = "./.temp/postgresql-nodejs.zip"
  function_name = "benchmark-postgresql-nodejs"
  role          = aws_iam_role.benchmark_postgresql_nodejs.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_benchmark_postgresql_nodejs.output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.deploy_zones.ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ConnectionString = "postgres://${local.rds_username}:${local.rds_password}@${local.rds_address}:${local.rds_port}/${local.rds_db_name}"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark_postgresql_nodejs]
}

resource "aws_cloudwatch_log_group" "benchmark_postgresql_nodejs" {
  name              = "/aws/lambda/benchmark-postgresql-nodejs"
  retention_in_days = 1
}
