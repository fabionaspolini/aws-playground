resource "aws_iam_role" "simple_function_python" {
  name = "simple-function-python-lambda"

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

data "archive_file" "publish_simple_function_python" {
  type        = "zip"
  source_dir  = "../src/simple-function-python"
  output_path = "./.temp/simple-function-python.zip"
}

resource "aws_lambda_function" "simple_function_python" {
  filename      = "./.temp/simple-function-python.zip"
  function_name = "simple-function-python"
  role          = aws_iam_role.simple_function_python.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_simple_function_python.output_base64sha256

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.simple_function_python.name
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

resource "aws_cloudwatch_log_group" "simple_function_python" {
  name              = "/aws/lambda/simple-function-python"
  retention_in_days = 1
}
