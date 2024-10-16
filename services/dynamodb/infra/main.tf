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

  # stream_enabled   = true
  # stream_view_type = "NEW_AND_OLD_IMAGES"

  ttl {
    attribute_name = "ExpireOn"
    enabled        = true
  }

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

  local_secondary_index {
    name               = "VendasClienteId_LSI"
    range_key          = "ClienteId"
    projection_type    = "INCLUDE"
    non_key_attributes = ["SK"]
  }

  global_secondary_index {
    name           = "VendasPorClienteIndex"
    hash_key       = "ClienteId"
    range_key      = "SK"
    write_capacity = 1
    read_capacity  = 1

    # projection_type    = "ALL"
    projection_type    = "INCLUDE"
    non_key_attributes = ["Data", "ValorTotal", "Pagamento.Metodo", "Itens"] # Propriedes anihadas não são refletidas
  }
}

# Auto scaling policy

resource "aws_appautoscaling_target" "dynamodb_table_read_target" {
  min_capacity       = 1
  max_capacity       = 3
  resource_id        = "table/${aws_dynamodb_table.vendas.name}"
  scalable_dimension = "dynamodb:table:ReadCapacityUnits"
  service_namespace  = "dynamodb"
}

# Read capacity utilization autoscaling

resource "aws_appautoscaling_policy" "dynamodb_table_read_policy" {
  name               = "DynamoDBReadCapacityUtilization:${aws_appautoscaling_target.dynamodb_table_read_target.resource_id}"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "DynamoDBReadCapacityUtilization"
    }

    target_value = 85
  }
}

# Scheduled auto scaling

resource "aws_appautoscaling_scheduled_action" "dynamodb_table_read_up" {
  name               = "dynamodb-table-vendas-up"
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target.service_namespace
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target.scalable_dimension
  schedule           = "cron(49 21 * * ? *)"
  timezone           = "America/Sao_Paulo"

  scalable_target_action {
    min_capacity = 2
    max_capacity = 5
  }
}

resource "aws_appautoscaling_scheduled_action" "dynamodb_table_read_restore" {
  name               = "dynamodb-table-vendas-restore"
  service_namespace  = aws_appautoscaling_target.dynamodb_table_read_target.service_namespace
  resource_id        = aws_appautoscaling_target.dynamodb_table_read_target.resource_id
  scalable_dimension = aws_appautoscaling_target.dynamodb_table_read_target.scalable_dimension
  schedule           = "cron(54 21 * * ? *)"
  timezone           = "America/Sao_Paulo"

  scalable_target_action {
    min_capacity = aws_appautoscaling_target.dynamodb_table_read_target.min_capacity
    max_capacity = aws_appautoscaling_target.dynamodb_table_read_target.max_capacity
  }
}