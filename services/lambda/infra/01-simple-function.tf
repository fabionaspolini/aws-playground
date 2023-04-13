data "aws_iam_policy" "AWSXRayDaemonWriteAccess" {
  name = "AWSXRayDaemonWriteAccess"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "simple-function-lambda" {
  name = "simple-function-lambda"

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
  source_dir  = "../src/01-simple-function/publish"
  output_path = "./temp/publish.zip"
}

resource "aws_lambda_function" "simple-function" {
  filename      = "./temp/publish.zip"
  function_name = "simple-function"
  role          = aws_iam_role.simple-function-lambda.arn
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
}

# configurar log groud e retention