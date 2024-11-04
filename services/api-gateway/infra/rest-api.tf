variable "stage_name" {
  type    = string
  default = "dev"
}

resource "aws_api_gateway_rest_api" "example" {
  name = "example"
  endpoint_configuration {
    types = ["REGIONAL"]
  }

  body = file("./rest-api.openapi.yml")
}

resource "aws_api_gateway_deployment" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.example.body))
  }

  lifecycle {
    create_before_destroy = true
  }
}

#
# Stage and Stage Settings
#

resource "aws_api_gateway_stage" "example" {
  depends_on = [aws_cloudwatch_log_group.api_logs]

  deployment_id = aws_api_gateway_deployment.example.id
  rest_api_id   = aws_api_gateway_rest_api.example.id
  stage_name    = var.stage_name

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access_logging.arn
    format          = replace(replace(file("./rest-api.access-logging-format.json"), "\r\n", ""), "  ", "")
  }
}

resource "aws_api_gateway_method_settings" "example" {
  rest_api_id = aws_api_gateway_rest_api.example.id
  stage_name  = aws_api_gateway_stage.example.stage_name
  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO" # "ERROR" - Irá criar um log group automaticamente com nome "API-Gateway-Execution-Logs_{rest-api-id}/{stage-name} "
  }
}

#
# Log group - CloudWatch logs
#

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_api_gateway_rest_api.example.id}/${var.stage_name}"
  retention_in_days = 1
}

#
# Log group - Custom access logging
#

resource "aws_cloudwatch_log_group" "api_access_logging" {
  name              = "/aws/apigateway/${aws_api_gateway_rest_api.example.name}-${aws_api_gateway_rest_api.example.id}/${var.stage_name}/access-logging"
  retention_in_days = 1
}