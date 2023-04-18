resource "aws_iam_role" "benchmark_data_access_dapper-aot_jit" {
  name = "benchmark-data-access-dapper_aot-jit-lambda"

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
resource "null_resource" "publish_benchmark_data_access_dapper-aot_jit" {
  provisioner "local-exec" {
    working_dir = "../src/data-access-dapper_aot-jit"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_benchmark_data_access_dapper-aot_jit" {
  type        = "zip"
  source_dir  = "../src/data-access-dapper_aot-jit/publish"
  output_path = "./.temp/data-access-dapper_aot-jit.zip"
  depends_on  = [null_resource.publish_benchmark_data_access_dapper-aot_jit]
}

resource "aws_lambda_function" "benchmark_data_access_dapper-aot_jit" {
  filename      = "./.temp/data-access-dapper_aot-jit.zip"
  function_name = "benchmark-data-access-dapper_aot-jit"
  role          = aws_iam_role.benchmark_data_access_dapper-aot_jit.arn
  handler       = "DataAccess.DapperAot.Jit::DataAccess.DapperAot.Jit.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 30
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_benchmark_data_access_dapper-aot_jit.output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.deploy_zones.ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ConnectionString = "${local.connection_string};Application Name=benchmark-data-access-dapper_aot-jit-lambda;"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark_data_access_dapper-aot_jit]
}

resource "aws_cloudwatch_log_group" "benchmark_data_access_dapper-aot_jit" {
  name              = "/aws/lambda/benchmark-data-access-dapper_aot-jit"
  retention_in_days = 1
}
