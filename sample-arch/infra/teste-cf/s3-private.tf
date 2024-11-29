resource "aws_s3_bucket" "bucket" {
  bucket        = "teste-cf-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
  # Apenas para testes - Está propriedade permite que o `terraform destroy` exclua todos os objetos e apague o bucket, resultando em perda de dados
}

#
# Upload file
#

resource "aws_s3_object" "bucket_object_txt" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "teste.txt"
  source       = "C:/Temp/teste.txt"
  etag = filemd5("C:/Temp/teste.txt")
  content_type = "text/plain"
}

resource "aws_s3_object" "bucket_object_json" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "teste.json"
  source       = "C:/Temp/teste.json"
  etag = filemd5("C:/Temp/teste.json")
  content_type = "application/json"
}

resource "aws_s3_object" "bucket_object_png" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "teste.png"
  source       = "C:/Temp/teste.png"
  etag = filemd5("C:/Temp/teste.png")
  content_type = "image/png"
}

resource "aws_s3_object" "bucket_object_js" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "teste.js"
  source       = "C:/Temp/teste.js"
  etag = filemd5("C:/Temp/teste.js")
  content_type = "text/javascript"
}

resource "aws_s3_object" "bucket_object_html" {
  bucket       = aws_s3_bucket.bucket.id
  key          = "teste.html"
  source       = "C:/Temp/teste.html"
  etag = filemd5("C:/Temp/teste.html")
  content_type = "text/html"
}