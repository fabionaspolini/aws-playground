resource "aws_dynamodb_table" "venda" {
  name         = "Venda"
  billing_mode = "PAY_PER_REQUEST"
  hash_key       = "AnoMes" # Particionamento por este campo - YYYYMM
  range_key      = "Id" # Composição adicional da chave primária. Identificador único em conjunto com o hash_key

  attribute {
    name = "AnoMes"
    type = "S"
  }

  attribute {
    name = "Id"
    type = "S"
  }

#   ttl {
#     attribute_name = "TimeToExist"
#     enabled        = false
#   }
}
