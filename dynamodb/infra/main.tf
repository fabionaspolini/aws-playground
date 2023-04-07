resource "aws_dynamodb_table" "venda" {
  name         = "Venda"

  # > Capacity settings: On-demand
  # billing_mode = "PAY_PER_REQUEST"

  # > Capacity settings: Provisined
  billing_mode = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  # -- end of Capacity settings

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
