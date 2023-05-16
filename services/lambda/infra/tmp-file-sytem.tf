resource "aws_iam_role" "tmp_file_sytem" {
  name = "tmp-file-sytem-lambda"

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
resource "null_resource" "publish_tmp_file_sytem" {
  provisioner "local-exec" {
    working_dir = "../src/tmp-file-sytem"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_tmp_file_sytem" {
  type        = "zip"
  source_dir  = "../src/tmp-file-sytem/bin/release/publish"
  output_path = "./.temp/tmp-file-sytem.zip"
  depends_on  = [null_resource.publish_tmp_file_sytem]
}

resource "aws_lambda_function" "tmp_file_sytem" {
  filename      = "./.temp/tmp-file-sytem.zip"
  function_name = "tmp-file-sytem"
  role          = aws_iam_role.tmp_file_sytem.arn
  handler       = "TmpFileSystemPlayground::TmpFileSystemPlayground.Function::FunctionHandler"
  runtime       = "dotnet6"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_tmp_file_sytem.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.tmp_file_sytem]
}

resource "aws_cloudwatch_log_group" "tmp_file_sytem" {
  name              = "/aws/lambda/tmp-file-sytem"
  retention_in_days = 1
}
