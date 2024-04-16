resource "aws_iam_role" "string_upper_case" {
  name = "string-upper-case-lambda"
  path = "/aws-playground/services/step-function/"

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
resource "null_resource" "publish_string_upper_case" {
  provisioner "local-exec" {
    working_dir = "../src/string-upper-case"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_string_upper_case" {
  type        = "zip"
  source_dir  = "../src/string-upper-case/publish"
  output_path = "./.temp/string-upper-case.zip"
  depends_on  = [null_resource.publish_string_upper_case]
}

resource "aws_lambda_function" "string_upper_case" {
  filename      = "./.temp/string-upper-case.zip"
  function_name = "string-upper-case-to-step-function-sample"
  role          = aws_iam_role.string_upper_case.arn
  handler       = "StringUpperCase::StringUpperCase.Function::FunctionHandler"
  runtime       = "dotnet8"
  memory_size   = 256
  timeout       = 15
  architectures = ["arm64"]

  source_code_hash = data.archive_file.publish_string_upper_case.output_base64sha256
  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.string_upper_case.name
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_cloudwatch_log_group" "string_upper_case" {
  name              = "/aws/lambda/aws-playground/services/step-function/string-upper-case-to-step-function-sample"
  retention_in_days = 1
}
