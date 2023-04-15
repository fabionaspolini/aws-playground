resource "aws_iam_role" "simple-function-jit-no-reflection" {
  name = "simple-function-jit-no-reflection-lambda"

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
resource "null_resource" "publish-simple-function-jit-no-reflection" {
  provisioner "local-exec" {
    working_dir = "../src/simple-function-jit-no-reflection"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish-simple-function-jit-no-reflection" {
  type        = "zip"
  source_dir  = "../src/simple-function-jit-no-reflection/publish"
  output_path = "./.temp/simple-function-jit-no-reflection.zip"
  depends_on  = [null_resource.publish-simple-function-jit-no-reflection]
}

resource "aws_lambda_function" "simple-function-jit-no-reflection" {
  filename      = "./.temp/simple-function-jit-no-reflection.zip"
  function_name = "simple-function-jit-no-reflection"
  role          = aws_iam_role.simple-function-jit-no-reflection.arn
  handler       = "SimpleFunctionJitNoReflection::SimpleFunctionJitNoReflection.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 10
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish-simple-function-jit-no-reflection.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.simple-function-jit-no-reflection]
}

resource "aws_cloudwatch_log_group" "simple-function-jit-no-reflection" {
  name              = "/aws/lambda/simple-function-jit-no-reflection"
  retention_in_days = 1
}