resource "aws_s3_bucket" "playground_private" {
  bucket        = "playground-private-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Apenas para testes - Está propriedade permite que o `terraform destroy` exclua todos os objetos e apague o bucket, resultando em perda de dados
}

#
# Upload file
#

resource "aws_s3_object" "playground_private_object" {
  bucket = aws_s3_bucket.playground_private.id
  key    = "README.md"
  source = "../README.md"
  etag   = filemd5("../README.md")
}