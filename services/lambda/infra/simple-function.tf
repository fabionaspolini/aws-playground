variable "lambda_function_name" {
  default = "simple-function"
}

variable "publish_zip_file" {
  default = "./.temp/simple-function.zip"
}

data "aws_iam_policy" "AWSXRayDaemonWriteAccess" {
  name = "AWSXRayDaemonWriteAccess"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "lambda" {
  name = "${var.lambda_function_name}-lambda"

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
resource "null_resource" "publish" {
  provisioner "local-exec" {
    working_dir = "../src/${var.lambda_function_name}"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish" {
  type        = "zip"
  source_dir  = "../src/${var.lambda_function_name}/publish"
  output_path = var.publish_zip_file
  depends_on  = [null_resource.publish]
}

resource "aws_lambda_function" "simple_function" {
  filename      = var.publish_zip_file
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda.arn
  handler       = "SimpleFunction::SimpleFunction.Function::FunctionHandler"
  runtime       = "dotnet6"

  source_code_hash = data.archive_file.publish.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda]
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 5
}
