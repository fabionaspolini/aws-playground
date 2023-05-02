# Maiores detalhes no arquivo /services/sqs/README.md

resource "aws_sqs_queue" "my_streaming_fifo" {
  name                       = "my-streaming.fifo"
  fifo_queue                 = true
  deduplication_scope        = "messageGroup"
  visibility_timeout_seconds = 5      # Tempo máximo que o consumidor tem para processar a mensagem. Após isso ela pode ser entregue novamente a outro consumer (max 12 horas)
  delay_seconds              = 0      # tempo para entregar primeira vez ao consumidor (max 15 min)
  receive_wait_time_seconds  = 20     # Se a fila estiver vazia, o polling aguarda este periodo antes de retornar um pacote vazio ao consumidor. Se uma mensagem entrar na fila neste intervalo, é encaminhada na hora para o consumidor (max 20 segundos)
  message_retention_seconds  = 86400  # 24 horas de retenção na fila (entre 1 min e 14 dias)
  max_message_size           = 262144 # 256 Kb (máximo)
}

resource "aws_sqs_queue" "my_streaming_standard" {
  name                       = "my-streaming-standard"
  fifo_queue                 = false
  visibility_timeout_seconds = 5      # Tempo máximo que o consumidor tem para processar a mensagem. Após isso ela pode ser entregue novamente a outro consumer (max 12 horas)
  delay_seconds              = 0      # tempo para entregar primeira vez ao consumidor (max 15 min)
  receive_wait_time_seconds  = 20     # Se a fila estiver vazia, o polling aguarda este periodo antes de retornar um pacote vazio ao consumidor. Se uma mensagem entrar na fila neste intervalo, é encaminhada na hora para o consumidor (max 20 segundos)
  message_retention_seconds  = 86400  # 24 horas de retenção na fila (entre 1 min e 14 dias)
  max_message_size           = 262144 # 256 Kb (máximo)
}
