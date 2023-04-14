resource "aws_iam_role" "context-details" {
  name = "context-details-lambda"

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
resource "null_resource" "publish-context-details" {
  provisioner "local-exec" {
    working_dir = "../src/context-details"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish-context-details" {
  type        = "zip"
  source_dir  = "../src/context-details/publish"
  output_path = "./.temp/context-details.zip"
  depends_on  = [null_resource.publish-context-details]
}

resource "aws_lambda_function" "context-details" {
  filename      = "./.temp/context-details.zip"
  function_name = "context-details"
  role          = aws_iam_role.context-details.arn
  handler       = "ContextDetails::ContextDetails.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 10
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish-context-details.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.context-details]
}

resource "aws_cloudwatch_log_group" "context-details" {
  name              = "/aws/lambda/context-details"
  retention_in_days = 1
}
