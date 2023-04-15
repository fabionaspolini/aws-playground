resource "aws_iam_role" "benchmark-data-access-jit" {
  name = "benchmark-data-access-jit-lambda"

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

  managed_policy_arns = [data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn, data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn]
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish-benchmark-data-access-jit" {
  provisioner "local-exec" {
    working_dir = "../src/data-access-jit"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish-benchmark-data-access-jit" {
  type        = "zip"
  source_dir  = "../src/data-access-jit/publish"
  output_path = "./.temp/data-access-jit.zip"
  depends_on  = [null_resource.publish-benchmark-data-access-jit]
}

resource "aws_lambda_function" "benchmark-data-access-jit" {
  filename      = "./.temp/data-access-jit.zip"
  function_name = "benchmark-data-access-jit"
  role          = aws_iam_role.benchmark-data-access-jit.arn
  handler       = "DataAccess.Jit::DataAccess.Jit.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 10
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish-benchmark-data-access-jit.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ConnectionString = var.ConnectionString
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark-data-access-jit]
}

resource "aws_cloudwatch_log_group" "benchmark-data-access-jit" {
  name              = "/aws/lambda/benchmark-data-access-jit"
  retention_in_days = 1
}
