variable "kinesis_firehose_name" {
  type    = string
  default = "api-gateway-access-logging"
}

#
# Kinesis Firehose
#

resource "aws_kinesis_firehose_delivery_stream" "api_gateway_access_logging" {
  name        = var.kinesis_firehose_name
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.api_gateway_access_logging.arn
    role_arn   = aws_iam_role.api_gateway_access_logging_kinesis_firehose.arn

    buffering_size     = 1  # MB
    buffering_interval = 15 # segundos
    file_extension     = ".gz" # formato do loggroup para o subscription filter é gzip
    custom_time_zone   = "America/Sao_Paulo"

    processing_configuration {
      enabled = true
      processors {
        type = "AppendDelimiterToRecord"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.api_gateway_access_logging_kinesis_firehose.name
      log_stream_name = aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.name
    }
  }
}

#
# Log Group
#

resource "aws_cloudwatch_log_group" "api_gateway_access_logging_kinesis_firehose" {
  name              = "/aws/kinesisfirehose/${var.kinesis_firehose_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "api_gateway_access_logging_error_stream" {
  name           = "Error" # Delivery padrão do Kinesis Firehose
  log_group_name = aws_cloudwatch_log_group.api_gateway_access_logging_kinesis_firehose.name
}

#
# Role - Execução pelo job do Kinesis
#

resource "aws_iam_role" "api_gateway_access_logging_kinesis_firehose" {
  name               = "${var.kinesis_firehose_name}-kinesis-firehose"
  path               = "/aws-playground/sample-arch/"
  assume_role_policy = data.aws_iam_policy_document.trust_policy_from_firehose.json
}

resource "aws_iam_role_policy" "api_gateway_access_logging_kinesis_firehose_inline_policy" {
  name = "inline-policy"
  role = aws_iam_role.api_gateway_access_logging_kinesis_firehose.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:*",
        ]
        Resource = [
          aws_cloudwatch_log_group.api_gateway_access_logging_kinesis_firehose.arn,
           aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.arn,
          "${aws_cloudwatch_log_group.api_gateway_access_logging_kinesis_firehose.arn}:*",
          "${aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.arn}:*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_access_logging_kinesis_firehose_role_attach_s3_bucket_put_object" {
  role       = aws_iam_role.api_gateway_access_logging_kinesis_firehose.name
  policy_arn = aws_iam_policy.api_gateway_access_logging_bucket_put_object.arn
}

#
# Policy - Publish no Kinesis firehose
#

resource "aws_iam_policy" "api_gateway_access_logging_kinesis_firehose_policy" {
  name        = "${aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.name}-kinesis-firehose-put-record"
  path        = "/aws-playground/sample-arch/"
  description = "Publicar no kinesis firehose '${aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "firehose:DeleteDeliveryStream",
          "firehose:PutRecord",
          "firehose:PutRecordBatch",
          "firehose:UpdateDestination"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.arn
        ]
      },
    ]
  })
}