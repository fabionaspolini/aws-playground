# após 3 erros, envia para "my-action-dlq-auto-retry"
# fila de ação principal, deve ter auto scale nos consumidores para alta performance
resource "aws_sqs_queue" "my_action" {
  name                       = "my-action"
  visibility_timeout_seconds = 5     # Tempo máximo que o consumidor tem para processar a mensagem. Após isso ela pode ser entregue novamente a outro consumer (max 12 horas)
  delay_seconds              = 0      # tempo para entregar primeira vez ao consumidor (max 15 min)
  receive_wait_time_seconds  = 0      # Tempo que o pooling deve aguardar para retornar ao consumidor (ajuda a melhorar os custos) (max 20 segundos)
  message_retention_seconds  = 86400  # 24 horas de retenção na fila (entre 1 min e 14 dias)
  max_message_size           = 262144 # 256 Kb (máximo)
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.my_action_retry.arn
    maxReceiveCount     = 3
  })
}

# mensagem entra e após 10 segundos (delay_seconds) é entregue ao consumidor
# se continuar com erro, não faz delete e após 30 segundos (visibility_timeout_seconds) será entregue a outro consumir
# ao falhar 10 vezes, envia para "my-action-dlq-dead"
# fila de tratamento de erros. Não deve ter autoscaling para não consumir recursos desnecessário.
resource "aws_sqs_queue" "my_action_retry" {
  name                       = "my-action-retry"
  visibility_timeout_seconds = 30     # Tempo máximo que o consumidor tem para processar a mensagem. Após isso ela pode ser entregue novamente a outro consumer (max 12 horas)
  delay_seconds              = 10     # tempo para entregar primeira vez ao consumidor (max 15 min)
  receive_wait_time_seconds  = 0      # Tempo que o pooling deve aguardar para retornar ao consumidor (ajuda a melhorar os custos) (max 20 segundos)
  message_retention_seconds  = 86400  # 24 horas de retenção na fila (entre 1 min e 14 dias)
  max_message_size           = 262144 # 256 Kb (máximo)
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.my_action_dlq.arn
    maxReceiveCount     = 10
  })
}

# Para limitar tempo em auto retry
resource "aws_sqs_queue" "my_action_dlq" {
  name                       = "my-action-dlq"
  visibility_timeout_seconds = 30     # Tempo máximo que o consumidor tem para processar a mensagem. Após isso ela pode ser entregue novamente a outro consumer (max 12 horas)
  delay_seconds              = 0      # tempo para entregar primeira vez ao consumidor (max 15 min)
  receive_wait_time_seconds  = 0      # Tempo que o pooling deve aguardar para retornar ao consumidor (ajuda a melhorar os custos) (max 20 segundos)
  message_retention_seconds  = 86400  # 24 horas de retenção na fila (entre 1 min e 14 dias)
  max_message_size           = 262144 # 256 Kb (máximo)
}
