resource "aws_iam_role" "context_details" {
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

  managed_policy_arns = [
    data.aws_iam_policy.AWSLambdaBasicExecutionRole.arn,
    data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn
  ]
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish_context_details" {
  provisioner "local-exec" {
    working_dir = "../src/context-details"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_context_details" {
  type        = "zip"
  source_dir  = "../src/context-details/publish"
  output_path = "./.temp/context-details.zip"
  depends_on  = [null_resource.publish_context_details]
}

resource "aws_lambda_function" "context_details" {
  filename      = "./.temp/context-details.zip"
  function_name = "context-details"
  role          = aws_iam_role.context_details.arn
  handler       = "ContextDetails::ContextDetails.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_context_details.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.context_details]
}

resource "aws_cloudwatch_log_group" "context_details" {
  name              = "/aws/lambda/context-details"
  retention_in_days = 1
}
