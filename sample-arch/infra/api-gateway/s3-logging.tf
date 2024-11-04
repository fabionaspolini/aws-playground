resource "aws_s3_bucket" "api_gateway_access_logging" {
  bucket        = "api-gateway-access-logging-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Apenas para testes - Está propriedade permite que o `terraform destroy` exclua todos os objetos e apague o bucket, resultando em perda de dados
}

resource "aws_iam_policy" "api_gateway_access_logging_bucket_put_object" {
  name        = "api-gateway-access-logging-bucket-put-object"
  path        = "/aws-playground/sample-arch/"
  description = "Criar arquivos nos bucket 'api-gateway-access-logging-${data.aws_caller_identity.current.account_id}'"

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
          "arn:aws:s3:::api-gateway-access-logging-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::api-gateway-access-logging-${data.aws_caller_identity.current.account_id}/*"
        ]
      }
    ]
  })
}