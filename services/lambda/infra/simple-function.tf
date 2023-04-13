variable "lambda_function_name" {
  default = "simple-function"
}

variable "publish_zip_file" {
  default = "./temp/simple-function.zip"
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

data "archive_file" "publish" {
  type        = "zip"
  source_dir  = "../src/simple-function/publish"
  output_path = var.publish_zip_file
}

resource "aws_lambda_function" "simple-function" {
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

  depends_on = [
    aws_cloudwatch_log_group.lambda
  ]
}

resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${var.lambda_function_name}"
  retention_in_days = 5
}