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

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_basic_playground.arn
    role_arn           = aws_iam_role.api_gateway_access_logging_firehose.arn
  }

  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.api_gateway_access_logging.arn
    role_arn   = aws_iam_role.api_gateway_access_logging_firehose.arn

    buffering_size     = 1     # MB
    buffering_interval = 15    # segundos
    file_extension     = ".gz" # formato do loggroup para o subscription filter é gzip
    custom_time_zone   = "America/Sao_Paulo"

    error_output_prefix = "/errors/"

    processing_configuration {
      enabled = true
      processors {
        type = "AppendDelimiterToRecord"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.api_gateway_access_logging_firehose.name
      log_stream_name = aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.name
    }

    # s3_backup_mode = "Enabled"
    # s3_backup_configuration {
    #   bucket_arn         = aws_s3_bucket.api_gateway_access_logging_firehose_backup.arn
    #   role_arn           = aws_iam_role.api_gateway_access_logging_firehose.arn
    #   buffering_size     = 1
    #   buffering_interval = 60
    # }
  }
}

#
# S3 backup
#

# resource "aws_s3_bucket" "api_gateway_access_logging_firehose_backup" {
#   bucket        = "api-gateway-access-logging-firehose-backup-${data.aws_caller_identity.current.account_id}"
#   force_destroy = true # Apenas para testes - Está propriedade permite que o `terraform destroy` exclua todos os objetos e apague o bucket, resultando em perda de dados
# }
# 
# resource "aws_iam_policy" "api_gateway_access_logging_firehose_backup_bucket_put_object" {
#   name        = "api-gateway-access-logging-firehose-backup-bucket-put-object"
#   path        = "/aws-playground/sample-arch/"
#   description = "Criar arquivos nos bucket 'api-gateway-access-logging-${data.aws_caller_identity.current.account_id}'"
# 
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Action = [
#           # "s3:AbortMultipartUpload",
#           # "s3:GetBucketLocation",
#           # "s3:GetObject",
#           # "s3:ListBucket",
#           # "s3:ListBucketMultipartUploads",
#           # "s3:PutObject"
#           "s3:*"
#         ]
#         Resource = [
#           aws_s3_bucket.api_gateway_access_logging_firehose_backup.arn,
#           "${aws_s3_bucket.api_gateway_access_logging_firehose_backup.arn}/*"
#         ]
#       }
#     ]
#   })
# }

#
# Log Group
#

resource "aws_cloudwatch_log_group" "api_gateway_access_logging_firehose" {
  name              = "/aws/kinesisfirehose/${var.kinesis_firehose_name}"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "api_gateway_access_logging_error_stream" {
  name           = "Error" # Delivery padrão do Kinesis Firehose
  log_group_name = aws_cloudwatch_log_group.api_gateway_access_logging_firehose.name
}

#
# Shared Policy - Para outros recursos publicarem no kinesis firehose
#

resource "aws_iam_policy" "api_gateway_access_logging_firehose_policy" {
  name        = "${aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.name}-firehose-put-record"
  path        = "/aws-playground/sample-arch/"
  description = "Publicar no kinesis firehose '${aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # "firehose:DeleteDeliveryStream",
          # "firehose:PutRecord",
          # "firehose:PutRecordBatch",
          # "firehose:UpdateDestination"
          "firehose:*"
        ]
        Resource = [
          aws_kinesis_firehose_delivery_stream.api_gateway_access_logging.arn
        ]
      },
    ]
  })
}

#
# Role - Execução pelo job do Kinesis
#

resource "aws_iam_role" "api_gateway_access_logging_firehose" {
  name               = "${var.kinesis_firehose_name}-firehose"
  path               = "/aws-playground/sample-arch/"
  assume_role_policy = data.aws_iam_policy_document.trust_policy_from_firehose.json
}

resource "aws_iam_role_policy" "api_gateway_access_logging_firehose_inline_policy" {
  name = "inline-policy"
  role = aws_iam_role.api_gateway_access_logging_firehose.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:*",
        ]
        Resource = [
          aws_cloudwatch_log_group.api_gateway_access_logging_firehose.arn,
          aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.arn,
          "${aws_cloudwatch_log_group.api_gateway_access_logging_firehose.arn}:*",
          "${aws_cloudwatch_log_stream.api_gateway_access_logging_error_stream.arn}:*",
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_access_logging_firehose_role_attach_s3_bucket_put_object" {
  role       = aws_iam_role.api_gateway_access_logging_firehose.name
  policy_arn = aws_iam_policy.api_gateway_access_logging_bucket_put_object.arn
}

resource "aws_iam_role_policy_attachment" "api_gateway_access_logging_firehose_role_from_stream" {
  role       = aws_iam_role.api_gateway_access_logging_firehose.name
  policy_arn = aws_iam_policy.api_gateway_access_logging_stream_policy.arn
}

# resource "aws_iam_role_policy_attachment" "api_gateway_access_logging_firehose_role_attach_s3_backup_bucket_put_object" {
#   role       = aws_iam_role.api_gateway_access_logging_firehose.name
#   policy_arn = aws_iam_policy.api_gateway_access_logging_firehose_backup_bucket_put_object.arn
# }