resource "aws_iam_role" "simple-function-no-reflection" {
  name = "simple-function-no-reflection-lambda"

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

# Exemplo para executar script local pelo terraform apenas para facilitar o deploy durante os estudos. Numa pipeline de CI/CD isso já estaria previamente gerado e seria desnecessário.
resource "null_resource" "publish-simple-function-no-reflection" {
  provisioner "local-exec" {
    working_dir = "../src/simple-function-no-reflection"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish-simple-function-no-reflection" {
  type        = "zip"
  source_dir  = "../src/simple-function-no-reflection/publish"
  output_path = "./.temp/simple-function-no-reflection.zip"
  depends_on  = [null_resource.publish-simple-function-no-reflection]
}

resource "aws_lambda_function" "simple-function-no-reflection" {
  filename      = "./.temp/simple-function-no-reflection.zip"
  function_name = "simple-function-no-reflection"
  role          = aws_iam_role.simple-function-no-reflection.arn
  handler       = "SimpleFunctionNoReflection::SimpleFunctionNoReflection.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 10
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish-simple-function-no-reflection.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.simple-function-no-reflection]
}

resource "aws_cloudwatch_log_group" "simple-function-no-reflection" {
  name              = "/aws/lambda/simple-function-no-reflection"
  retention_in_days = 1
}
