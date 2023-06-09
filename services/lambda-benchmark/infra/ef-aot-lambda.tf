# Para habiltiar/desabilitar o deploy da function, atualize a constante "deploy_benchmark_ef_aot" no arquivo "locals.tf".
# Comando "terraform apply" no windows não suporta este build.

resource "aws_iam_role" "benchmark_ef_aot" {
  name = "benchmark-ef-aot-lambda"

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
    data.aws_iam_policy.AWSXRayDaemonWriteAccess.arn,
    resource.aws_iam_policy.ManageNetworkInterface.arn
  ]
}

# Neste exemplo de estudos está sendo executado o script de build and publish da aplicação para garantir o deploy atualizado do código.
# Numa pipeline de CI/CD isso é desnecessário por você já terá os artefatos gerados previamente.
# resource "null_resource" "publish_benchmark_ef_aot" {
#   count = local.deploy_benchmark_ef_aot ? 1 : 0
#   provisioner "local-exec" {
#     working_dir = "../src/ef-aot"
#     command     = "publish-with-docker.sh"
#     interpreter = ["bash"]
#   }
#   triggers = {
#     always_run = "${timestamp()}" # Forçar deploy. Trigger é apenas uma lista de chave/valor e conforme gerenciamento de state do terraform, qualquer alteração de propriedade implica em deploy.
#   }
# }

# Comentado parte que compila com o docker porque o build com o EF é muito grande e demorado. Quando executando em concorrêcia com outros pelo terraform, frequentemente da crash no wsl
data "archive_file" "publish_benchmark_ef_aot" {
  count       = local.deploy_benchmark_ef_aot ? 1 : 0
  type        = "zip"
  source_file = "../src/ef-aot/bin/Release/publish/bootstrap" # ignorar arquivo bootstrap.dbg para o zip não exceder o tamanho máximo de upload direto para lambda (50 mb)
  output_path = "./.temp/ef-aot.zip"
  # depends_on  = [null_resource.publish_benchmark_ef_aot]
}

# se deploy for maior que 50 MB, é obrigatório passar pela lambda. 250 Mb descompactado é o limite.
# resource "aws_s3_object" "publish_benchmark_ef_aot" {
#   count      = local.deploy_benchmark_ef_aot ? 1 : 0
#   bucket     = aws_s3_bucket.temporary_deployment.id
#   key        = "lambdas/benchmark-ef-aot.zip"
#   source     = data.archive_file.publish_benchmark_ef_aot[0].output_path
#   etag       = data.archive_file.publish_benchmark_ef_aot[0].output_base64sha256
#   # etag       = filemd5("myfiles/yourfile.txt")
#   # depends_on = [data.archive_file.publish_benchmark_ef_aot]
# }

resource "aws_lambda_function" "benchmark_ef_aot" {
  count         = local.deploy_benchmark_ef_aot ? 1 : 0
  filename      = "./.temp/ef-aot.zip"
  function_name = "benchmark-ef-aot"
  role          = aws_iam_role.benchmark_ef_aot.arn
  handler       = "bootstrap"
  runtime       = "provided.al2"
  memory_size   = 256
  timeout       = 15
  architectures = ["x86_64"]

  # s3_bucket        = aws_s3_bucket.temporary_deployment.id
  # s3_key           = aws_s3_object.publish_benchmark_ef_aot[0].key
  source_code_hash = data.archive_file.publish_benchmark_ef_aot[0].output_base64sha256

  vpc_config {
    subnet_ids         = data.aws_subnets.deploy_zones.ids
    security_group_ids = [data.aws_security_group.default.id]
  }

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      ConnectionString = "${local.connection_string};Application Name=benchmark-ef-aot-lambda"
    }
  }

  depends_on = [aws_cloudwatch_log_group.benchmark_ef_aot]
}

resource "aws_cloudwatch_log_group" "benchmark_ef_aot" {
  name              = "/aws/lambda/benchmark-ef-aot"
  retention_in_days = 1
}
