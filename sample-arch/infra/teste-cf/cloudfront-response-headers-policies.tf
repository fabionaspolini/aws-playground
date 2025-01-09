resource "aws_cloudfront_response_headers_policy" "image_png" {
  name    = "content-type-png"
  comment = "content-type: image/png"

  security_headers_config {
    content_type_options {
      override = true
    }
  }

  custom_headers_config {
    items {
      header   = "Content-Type"
      override = true
      value    = "image/png"
    }
  }
}