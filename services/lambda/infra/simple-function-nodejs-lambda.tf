resource "aws_iam_role" "simple_function_nodejs" {
  name = "simple-function-nodejs-lambda"

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

data "archive_file" "publish_simple_function_nodejs" {
  type        = "zip"
  source_dir  = "../src/simple-function-nodejs"
  output_path = "./.temp/simple-function-nodejs.zip"
}

resource "aws_lambda_function" "simple_function_nodejs" {
  filename      = "./.temp/simple-function-nodejs.zip"
  function_name = "simple-function-nodejs"
  role          = aws_iam_role.simple_function_nodejs.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_simple_function_nodejs.output_base64sha256

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.simple_function_nodejs.name
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

resource "aws_cloudwatch_log_group" "simple_function_nodejs" {
  name              = "/aws/lambda/simple-function-nodejs"
  retention_in_days = 1
}
