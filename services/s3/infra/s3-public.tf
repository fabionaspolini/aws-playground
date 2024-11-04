resource "aws_s3_bucket" "playground_public" {
  bucket        = "playground-public-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true # Apenas para testes - Está propriedade permite que o `terraform destroy` exclua todos os objetos e apague o bucket, resultando em perda de dados
}

resource "aws_s3_bucket_ownership_controls" "playground_public" {
  bucket = aws_s3_bucket.playground_public.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "playground_public" {
  bucket = aws_s3_bucket.playground_public.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "playground_public" {
  depends_on = [
    aws_s3_bucket_ownership_controls.playground_public,
    aws_s3_bucket_public_access_block.playground_public,
  ]

  bucket = aws_s3_bucket.playground_public.id
  acl    = "private"
  # acl    = "public-read"
}

#
# Upload file
#

resource "aws_s3_object" "playground_public_object" {
  bucket = aws_s3_bucket.playground_public.id
  key    = "README.md"
  source = "../README.md"
  etag   = filemd5("../README.md")
  acl    = "public-read"
}