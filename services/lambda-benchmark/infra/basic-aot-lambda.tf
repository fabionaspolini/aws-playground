# Para habiltiar/desabilitar o deploy da function, atualize a constante "deploy_benchmark_basic_aot" no arquivo "locals.tf".
# Comando "terraform apply" no windows não suporta este build.

resource "aws_iam_role" "benchmark_basic_aot" {
  name = "benchmark-basic-aot-lambda"

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
    data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn
  ]
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish_benchmark_basic_aot" {
  count = local.deploy_benchmark_basic_aot ? 1 : 0
  provisioner "local-exec" {
    working_dir = "../src/basic-aot"
    command     = "publish-with-docker.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_benchmark_basic_aot" {
  count       = local.deploy_benchmark_basic_aot ? 1 : 0
  type        = "zip"
  source_dir  = "../src/basic-aot/bin/Release/publish"
  output_path = "./.temp/basic-aot.zip"
  depends_on  = [null_resource.publish_benchmark_basic_aot]
}

resource "aws_lambda_function" "benchmark_basic_aot" {
  count         = local.deploy_benchmark_basic_aot ? 1 : 0
  filename      = "./.temp/basic-aot.zip"
  function_name = "benchmark-basic-aot"
  role          = aws_iam_role.benchmark_basic_aot.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_benchmark_basic_aot[0].output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark_basic_aot]
}

resource "aws_cloudwatch_log_group" "benchmark_basic_aot" {
  name              = "/aws/lambda/benchmark-basic-aot"
  retention_in_days = 1
}
