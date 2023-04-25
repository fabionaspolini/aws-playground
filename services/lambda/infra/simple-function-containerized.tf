resource "aws_iam_role" "simple_function_containerized" {
  name = "simple-function-containerized-lambda"

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
resource "null_resource" "publish_simple_function_containerized" {
  provisioner "local-exec" {
    working_dir = "../src/simple-function-containerized"
    command     = "publish.sh"
    interpreter = ["bash"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }
}

data "archive_file" "publish_simple_function_containerized" {
  type        = "zip"
  source_dir  = "../src/simple-function-containerized/publish"
  output_path = "./.temp/simple-function-containerized.zip"
  depends_on  = [null_resource.publish_simple_function_containerized]
}

resource "aws_lambda_function" "simple_function_containerized" {
  filename      = "./.temp/simple-function-containerized.zip"
  function_name = "simple-function-containerized"
  role          = aws_iam_role.simple_function_containerized.arn
  handler       = "SimpleFunctionContainerized::SimpleFunctionContainerized.Function::FunctionHandler"
  runtime       = "dotnet6"
  package_type  = "Image"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  source_code_hash = data.archive_file.publish_simple_function_containerized.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [aws_cloudwatch_log_group.simple_function_containerized]
}

resource "aws_cloudwatch_log_group" "simple_function_containerized" {
  name              = "/aws/lambda/simple-function-containerized"
  retention_in_days = 1
}
