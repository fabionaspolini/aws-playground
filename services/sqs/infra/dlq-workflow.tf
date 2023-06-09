# Maiores detalhes no arquivo /services/sqs/README.md

# Fila principal: Deve ter auto scaling e serve para o fluxo demandado pela aplicação.
# Após 3 falhas, envia mensagem para "my-action-dlq-retry".
# Intervalo entre tentativas: 5 segundos
resource "aws_sqs_queue" "my_action" {
  name                       = "my-action"
  visibility_timeout_seconds = 5      # Tempo máximo que o consumidor tem para processar a mensagem. Após isso ela pode ser entregue novamente a outro consumer (max 12 horas)
  delay_seconds              = 0      # tempo para entregar primeira vez ao consumidor (max 15 min)
  receive_wait_time_seconds  = 20     # Se a fila estiver vazia, o polling aguarda este periodo antes de retornar um pacote vazio ao consumidor. Se uma mensagem entrar na fila neste intervalo, é encaminhada na hora para o consumidor (max 20 segundos)
  message_retention_seconds  = 86400  # 24 horas de retenção na fila (entre 1 min e 14 dias)
  max_message_size           = 262144 # 256 Kb (máximo)
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.my_action_dlq_retry.arn
    maxReceiveCount     = 3
  })
}

# Fila para retry de falhas. Não deve ter auto scaling para não consumir recursos desnecessários.
# Após 3 falhas, envia para "my-action-dlq"
# Intervalo entre tentativas: 10 segundos
# Caso de uso:
#   - Se for uma falha por motivo de um sistema terceiro inoperante, quando o mesmo for reestabelecido a integração será realizada.
#   - Se for falha por erro de código, temos a segurança de não consumir polling excessivamente na AWS.
#     Temos um tempo de vida delimitado para corrigir o sistema e implanta-lo para que o processo se reintregre automaticamente.
# Em ambos os casos:
#   - O tempo máximo para resiliência automática é de: "visibility_timeout_seconds" * "maxReceiveCount".
#   - Se haver muitas mensagens pendentes, elas não concorrerão com o fluxo online da aplicação, pois aqui não tem auto scaling.
#     A ideia é essa fila ser processada lentamente enquanto os recursos são utilizado pra dar conta da operação online na fila principal.
resource "aws_sqs_queue" "my_action_dlq_retry" {
  name                       = "my-action-dlq-retry"
  visibility_timeout_seconds = 10
  delay_seconds              = 0 # Essa propriedade não importa mais aqui pois é preservada mesma mensagem em todo o workflow. Ela vale apenas para a primeira entrega na fila principal.
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 1209600 # 14 dias
  max_message_size           = 262144
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.my_action_dlq.arn
    maxReceiveCount     = 3
  })
}

# Quando a mensagem cair aqui não deve mais haver um retry automatico pelo sistema, pois sem monitoramente adequado, não será corrigido e implicará em custo de consumo da fila.
# Se a janela de tempo de retry não foi suficiente para correção do problema e você implantar a correção após a mensagem estar aqui, você pode:
#   - 1: Conectar o consumer nesta fila momentâneamente até zera-la e depois desconecta-lo. Lembre-se: O esperado é que nunca chegue nada aqui e não queremos ter o risco de gastar $$$$ sem necessidade
#   - 2: Fazer uma rotina que mova as mensagens para fila de retry ou para principal
#        Esse cenário é mais interessante, você pode jogar uma parcela de mensagens para a fila de retry. Se processar com sucesso, você pode jogar tudo para principal,
#        pois nela existe auto scaling para reprocessar rapidamente.
resource "aws_sqs_queue" "my_action_dlq" {
  name                       = "my-action-dlq"
  visibility_timeout_seconds = 30
  delay_seconds              = 0
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 1209600 # 14 dias
  max_message_size           = 262144
}
