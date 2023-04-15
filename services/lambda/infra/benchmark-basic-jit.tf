resource "aws_iam_role" "benchmark-basic-jit" {
  name = "benchmark-basic-jit-lambda"

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
resource "null_resource" "publish-benchmark-basic-jit" {
  provisioner "local-exec" {
    working_dir = "../src/benchmark-basic-jit"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish-benchmark-basic-jit" {
  type        = "zip"
  source_dir  = "../src/benchmark-basic-jit/publish"
  output_path = "./.temp/benchmark-basic-jit.zip"
  depends_on  = [null_resource.publish-benchmark-basic-jit]
}

resource "aws_lambda_function" "benchmark-basic-jit" {
  filename      = "./.temp/benchmark-basic-jit.zip"
  function_name = "benchmark-basic-jit"
  role          = aws_iam_role.benchmark-basic-jit.arn
  handler       = "BenchmarkBasicJit::BenchmarkBasicJit.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 10
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish-benchmark-basic-jit.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark-basic-jit]
}

resource "aws_cloudwatch_log_group" "benchmark-basic-jit" {
  name              = "/aws/lambda/benchmark-basic-jit"
  retention_in_days = 1
}
