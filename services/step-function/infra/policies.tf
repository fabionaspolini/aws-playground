data "aws_iam_policy" "AWSXRayDaemonWriteAccess" {
  name = "AWSXRayDaemonWriteAccess"
}

data "aws_iam_policy" "AWSLambdaBasicExecutionRole" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "state_machine_logs_delivery_full_access" {
  name        = "state-machine-logs-delivery-full-access"
  path        = "/aws-playground/services/step-function/"
  description = "Role genérica para gravação de log no CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogDelivery",
          "logs:CreateLogStream",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutLogEvents",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "state_machine_x_ray" {
  name        = "state-machine-x-ray"
  path        = "/aws-playground/services/step-function/"
  description = "Role genérica para gravação de segmentos no X-Ray"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords",
          "xray:GetSamplingRules",
          "xray:GetSamplingTargets"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_policy" "state_machine_lambda_invoke" {
  name        = "state-machine-lambda-invoke"
  path        = "/aws-playground/services/step-function/"
  description = "Role genérica para execução de lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}