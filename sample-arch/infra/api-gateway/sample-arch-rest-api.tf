variable "stage_name" {
  type    = string
  default = "dev"
}

resource "aws_api_gateway_rest_api" "sample" {
  name        = "sample-arch"
  description = "Sample Arch"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  body = file("./sample-arch-rest-api.openapi.yml")
}

resource "aws_api_gateway_deployment" "sample" {
  rest_api_id = aws_api_gateway_rest_api.sample.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.sample.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#
# Stage and Stage Settings
#

resource "aws_api_gateway_stage" "sample" {
  depends_on = [aws_cloudwatch_log_group.api_logs]

  deployment_id = aws_api_gateway_deployment.sample.id
  rest_api_id   = aws_api_gateway_rest_api.sample.id
  stage_name    = var.stage_name

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access_logging.arn
    format          = replace(replace(file("./sample-arch-rest-api.access-logging-format.json"), "\r\n", ""), "  ", "")
  }
}

resource "aws_api_gateway_method_settings" "sample" {
  rest_api_id = aws_api_gateway_rest_api.sample.id
  stage_name  = aws_api_gateway_stage.sample.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO" # "ERROR" - Irá criar um log group automaticamente com nome "API-Gateway-Execution-Logs_{sample-arch-rest-api-id}/{stage-name} "
  }
}

#
# Log group - CloudWatch logs
#

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.sample.id}/${var.stage_name}"
  retention_in_days = 1
}

#
# Log group - Custom access logging
#

resource "aws_cloudwatch_log_group" "api_access_logging" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.sample.name}-${aws_api_gateway_rest_api.sample.id}/${var.stage_name}/access-logging"
  retention_in_days = 1
}

#
# Log group - Custom access logging - Subscription filter to Kinesis firehose
#

resource "aws_cloudwatch_log_subscription_filter" "api_access_logging_to_kinesis_firehose_subscription_filter" {
  name            = "Kinesis Firehose"
  role_arn        = aws_iam_role.api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter.arn
  log_group_name  = aws_cloudwatch_log_group.api_access_logging.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.arn
  distribution    = "Random" # ByLogStream, Random
}

resource "aws_iam_role" "api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter" {
  name                = "api-gateway-access-logging-log-group-to-kinesis-firehose-sub-fil"
  path                = "/aws-playground/sample-arch/"
  assume_role_policy  = data.aws_iam_policy_document.trust_policy_for_cloud_watch_logs.json
}

# resource "aws_iam_role_policy" "api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter_inline_policy" {
#   name = "inline-policy"
#   role = aws_iam_role.api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter.id
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           "logs:*",
#         ]
#         Resource = [
#           aws_cloudwatch_log_group.api_gateway_access_logging_kinesis_firehose.arn,
#           "${aws_cloudwatch_log_group.api_gateway_access_logging_kinesis_firehose.arn}:*",
#           # aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.arn
#         ]
#       },
#     ]
#   })
# }

resource "aws_iam_role_policy_attachment" "api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter_role_attach" {
  role       = aws_iam_role.api_gateway_access_logging_log_group_to_kinesis_firehose_subscription_filter.name
  policy_arn = aws_iam_policy.api_gateway_access_logging_kinesis_firehose_policy.arn
}
