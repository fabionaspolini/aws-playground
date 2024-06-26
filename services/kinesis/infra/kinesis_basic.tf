# Recursos criados:
# - Kinesis Data Stream
# - Bucket S3
# - Kinesis Firehose
# - Log group + log stream
# - Role + policy

# O que este exemplo faz?
# - Recebe um input no Data Stream
# - Repassa para o Firehouse agrupar por tamanho e tempo
# - Escreve agrupamento no S3

# Para utilizar este template, altere os textos:
# - kinesis-basic-playground
# - kinesis_basic_playground

###################################
###     Kinesis Data Stream     ###
###################################
resource "aws_kinesis_stream" "kinesis_basic_playground" {
  name = "kinesis-basic-playground"
  # shard_count      = 1 # Obrigatório se provisionado
  retention_period = 24

  # Armazenado no cloud watch e incrementa o custo da solução
  # shard_level_metrics = [
  #   "IncomingBytes",
  #   "OutgoingBytes",
  # ]

  stream_mode_details {
    stream_mode = "ON_DEMAND" # ON_DEMAND / PROVISIONED
  }
}

##################################
###     Bucket S3 - Target     ###
##################################

resource "aws_s3_bucket" "kinesis_basic_playground" {
  bucket        = "kinesis-basic-playground-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # permitir destruir arquivos no "terraform destroy"
}

################################
###     Kinesis Firehose     ###
################################

resource "aws_kinesis_firehose_delivery_stream" "kinesis_basic_playground" {
  name        = "kinesis-basic-playground"
  destination = "extended_s3"

  kinesis_source_configuration {
    kinesis_stream_arn = aws_kinesis_stream.kinesis_basic_playground.arn
    role_arn           = aws_iam_role.kinesis_basic_playground.arn
  }

  extended_s3_configuration {
    bucket_arn = aws_s3_bucket.kinesis_basic_playground.arn
    role_arn   = aws_iam_role.kinesis_basic_playground.arn

    buffering_size     = 1  # MB
    buffering_interval = 15 # segundos
    file_extension     = ".txt"
    custom_time_zone   = "America/Sao_Paulo"

    processing_configuration {
      enabled = true
      processors {
        type = "AppendDelimiterToRecord"
      }
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.kinesis_basic_playground.name
      log_stream_name = aws_cloudwatch_log_stream.kinesis_basic_playground_error_stream.name
    }
  }
}

#########################
###     Log Group     ###
#########################

# Log group
resource "aws_cloudwatch_log_group" "kinesis_basic_playground" {
  name              = "/aws/kinesisfirehose/kinesis-basic-playground"
  retention_in_days = 1
}

resource "aws_cloudwatch_log_stream" "kinesis_basic_playground_error_stream" {
  name           = "Error" # Delivery padrão do Kinesis Firehose
  log_group_name = aws_cloudwatch_log_group.kinesis_basic_playground.name
}

# resource "aws_cloudwatch_log_stream" "kinesis_basic_playground_backup_stream" {
#   name           = "Backup" # Delivery padrão do Kinesis Firehose
#   log_group_name = aws_cloudwatch_log_group.kinesis_basic_playground.name
# }

####################
###     Role     ###
####################

resource "aws_iam_role" "kinesis_basic_playground" {
  name                = "kinesis-basic-playground"
  path                = "/aws-playground/services/kinesis/"
  assume_role_policy  = data.aws_iam_policy_document.kinesis_basic_playground_assume_role.json
  managed_policy_arns = [aws_iam_policy.kinesis_basic_playground.arn]
}

data "aws_iam_policy_document" "kinesis_basic_playground_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "kinesis_basic_playground" {
  name        = "kinesis-basic-playground-policy"
  path        = "/aws-playground/services/kinesis/"
  description = "Role genérica para gravação de log no CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::kinesis-basic-playground-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::kinesis-basic-playground-${data.aws_caller_identity.current.account_id}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:PutLogEvents"
        ]
        Resource = [
          "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:/aws/kinesisfirehose/kinesis-basic-playground:log-stream:*"
        ]

        # "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:log-group:%FIREHOSE_POLICY_TEMPLATE_PLACEHOLDER%:log-stream:*"
      },
      {
        Effect = "Allow"
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Resource = [
          "arn:aws:kinesis:us-east-1:${data.aws_caller_identity.current.account_id}:stream/kinesis-basic-playground"
        ]
      },
    ]
  })
}