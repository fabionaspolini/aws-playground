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

resource "aws_ecr_repository" "simple_function_containerized" {
  name                 = "simple-function-containerized"
  image_tag_mutability = "MUTABLE"
  force_delete         = true # apagar mesmo com imagens existentes (habilitar apenas para testes)

  image_scanning_configuration {
    scan_on_push = false
  }
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
resource "null_resource" "publish_simple_function_containerized" {
  count = local.deploy_containerized_functions ? 1 : 0
  provisioner "local-exec" {
    working_dir = "../src/simple-function-containerized"
    command     = "bash ./publish.sh ${data.aws_caller_identity.current.account_id}"
    # interpreter = ["bash", "-c"]
  }
  triggers = {
    always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
  }

  depends_on = [aws_ecr_repository.simple_function_containerized]
}

resource "aws_lambda_function" "simple_function_containerized" {
  count         = local.deploy_containerized_functions ? 1 : 0
  function_name = "simple-function-containerized"
  role          = aws_iam_role.simple_function_containerized.arn
  package_type  = "Image"
  image_uri     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-1.amazonaws.com/simple-function-containerized:latest"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  # source_code_hash = "aaaash" # necessário atualizar o hash para aplicar atualização na hora

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      foo = "bar"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.simple_function_containerized,
    null_resource.publish_simple_function_containerized
  ]
}

resource "aws_cloudwatch_log_group" "simple_function_containerized" {
  name              = "/aws/lambda/simple-function-containerized"
  retention_in_days = 1
}
