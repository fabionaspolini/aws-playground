resource "aws_dynamodb_table" "vendas" {
  name = "Vendas"

  # > Capacity settings: On-demand
  # billing_mode = "PAY_PER_REQUEST"

  # > Capacity settings: Provisined
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  # -- end of Capacity settings

  hash_key  = "Id" # Particionamento dos dados
  range_key = "SK" # Composição adicional da chave primária. Identificador único em conjunto com o hash_key

  ttl {
    attribute_name = "ExpireOn"
    enabled        = true
  }

  global_secondary_index {
    name            = "VendasPorClienteIndex"
    hash_key        = "ClienteId"
    range_key       = "SK"
    write_capacity  = 1
    read_capacity   = 1
    projection_type = "ALL"

    # projection_type    = "INCLUDE"
    # non_key_attributes = ["Data", "ValorTotal", "Pagamento.Metodo", "Itens"] # Propriedes anihadas não são refletidas
  }

  # stream_enabled   = true
  # stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = {
    Owner       = "Fábio"
    Environment = "sample"
  }

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "SK"
    type = "S"
  }

  attribute {
    name = "ClienteId"
    type = "S"
  }
}
