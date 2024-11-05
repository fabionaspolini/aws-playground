variable "kinesis_stream_name" {
  type    = string
  default = "api-gateway-access-logging"
}

resource "aws_kinesis_stream" "kinesis_basic_playground" {
  name = var.kinesis_stream_name
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

#
# Shared Policy - Para outros recursos publicarem no kinesis firehose
#

resource "aws_iam_policy" "api_gateway_access_logging_stream_policy" {
  name        = "${aws_kinesis_stream.kinesis_basic_playground.name}-stream-get-record"
  path        = "/aws-playground/sample-arch/"
  description = "Publicar no kinesis data stream '${aws_kinesis_stream.kinesis_basic_playground.name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # "kinesis:DescribeStream",
          # "kinesis:GetShardIterator",
          # "kinesis:GetRecords",
          # "kinesis:ListShards"
          "kinesis:*"
        ]
        Resource = [
          aws_kinesis_stream.kinesis_basic_playground.arn
        ]
      },
    ]
  })
}