resource "aws_iam_role" "embedded_metric_producer" {
  name = "embedded-metric-producer-lambda"

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

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish_embedded_metric_producer" {
  provisioner "local-exec" {
    working_dir = "../src/embedded-metric-producer"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_embedded_metric_producer" {
  type        = "zip"
  source_dir  = "../src/embedded-metric-producer/publish"
  output_path = "./.temp/embedded-metric-producer.zip"
  depends_on  = [null_resource.publish_embedded_metric_producer]
}

resource "aws_lambda_function" "embedded_metric_producer" {
  filename      = "./.temp/embedded-metric-producer.zip"
  function_name = "embedded-metric-producer"
  role          = aws_iam_role.embedded_metric_producer.arn
  handler       = "EmbeddedMetricProducer::EmbeddedMetricProducer.Function::FunctionHandler"
  runtime       = "dotnet8"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_embedded_metric_producer.output_base64sha256

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.embedded_metric_producer.name
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

resource "aws_cloudwatch_log_group" "embedded_metric_producer" {
  name              = "/aws/lambda/embedded-metric-producer"
  retention_in_days = 1
}
