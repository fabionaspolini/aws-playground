# Para habiltiar/desabilitar o deploy da function, atualize a constante "deploy_benchmark_geral_aot" no arquivo "locals.tf".
# Comando "terraform apply" no windows não suporta este build.

resource "aws_iam_role" "benchmark_geral_aot" {
  name = "benchmark-geral-aot-lambda"

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
    data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn,
    data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn,
    resource.aws_iam_policy.ManageNetworkInterface.arn
  ]
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish_benchmark_geral_aot" {
  count = local.deploy_benchmark_geral_aot ? 1 : 0
  provisioner "local-exec" {
    working_dir = "../src/geral-aot"
    command     = "publish-with-docker.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_benchmark_geral_aot" {
  count       = local.deploy_benchmark_geral_aot ? 1 : 0
  type        = "zip"
  source_dir  = "../src/geral-aot/publish"
  output_path = "./.temp/geral-aot.zip"
  depends_on  = [null_resource.publish_benchmark_geral_aot]
}

resource "aws_lambda_function" "benchmark_geral_aot" {
  count         = local.deploy_benchmark_geral_aot ? 1 : 0
  filename      = "./.temp/geral-aot.zip"
  function_name = "benchmark-geral-aot"
  role          = aws_iam_role.benchmark_geral_aot.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"
  memory_size   = 256
  timeout       = 10
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_benchmark_geral_aot[0].output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.deploy_zones.ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ConnectionString = "${local.connection_string};Application Name=benchmark-geral-aot-lambda"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark_geral_aot]
}

resource "aws_cloudwatch_log_group" "benchmark_geral_aot" {
  name              = "/aws-playground/lambda-benchmark/geral-aot"
  retention_in_days = 1
}
