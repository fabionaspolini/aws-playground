# Kinesis

- [Visão Geral](#visão-geral)
- [Data Streams](#data-streams)


## Visão Geral

Ferramenta para trabalhar com stream de dados real time.

## Data Streams

- Provisionamento prévio do cluster
- Cluster é divido em shards
- O dado é dividido nos shards
- **Produtores:** Aplicações, estações de trabalho (pc/mobile/etc), SDKs, Kinesis Agent
  - Estrutura da mensagem:
    - Partition Key
    - Data blob (Até 1 Mb)
  - Cada shard recebe 1 MB/sec ou 1.000 msg/sec
  - Partition key direciona dado ao shard
  - Cuidado na seleção da partition key, se haver uma "hot key" (muito mais acesso que o normal), você pode receber "ProvisionedThroughputExceeded"
- **Consumidores:** Aplicações, Lambdas, Kinesis Data Firehouse, Kinesis Data Analytics
  - Estrutura da mensagem:
    - Partition Key
    - Sequence No.
    - Data blob
  - Tipos:
    - **Shared (Classic) fan-ou consumer:**
      - Limite 2 MB/sec compratilhado entre todos os consumidores do shard
      - O consumidor faz polling na api GetRecords()
      - Max 5 GetRecords api calls/sec
      - Latency ~200ms
      - Minimizar custos
      - Retorno de até 10 Mb (Throttle em 5 segundos) ou 10 mil registros
    - **Enchaced fran-out consumer:**
      - Limite 2 MB/sec por consumidor do shard
      - O consumidor faz o subscribe no shard pela nova api "SubscribeToShard()"
      - Latency ~70 ms
      - Maior custo
      - Soft limit de 5 consumer application por stream
- Retenção de dados entre 1 e 365 dias
- Pode reprocessar dados antigos
- O dado inserido não pode ser apagado
- O dado é armazanado sequencial no shard de acordo com a partition key
- Capacity mode
  - Provisioned
    - Cada shard suporta 1 Mb/s ou 1.000 msg/sec de entrada
    - Cada shard suporta 2 Mb/s de saída
    - Paga pelo shard provisionado por hora
  - On demand
    - Não há provisonamento ou gerenciamento
    - Capacidade de 4 Mb/sec ou 4.000 msgs/sec
    - Scala automatica com base no fluxo de 30 dias
    - Paga por hora e dados de entrada/saída Gb
- Security
  - Deploy na região
  - IAM policies
  - Para acessar da VPC precisa configurar o VPC endpoint (Para não trafegar pela internet)
  - Chamadas de API monitoradas pelo CloudTrail