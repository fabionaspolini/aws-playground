# Kinesis

- [Visão Geral](#visão-geral)
- [Estimativa de custos](#estimativa-de-custos)
- [Kinesis Data Streams](#kinesis-data-streams)
- [Kinesis Data Firehose](#kinesis-data-firehose)
- [Kinesis Data Analytics](#kinesis-data-analytics)
  - [Kinesis Data Analytics for SQL Applications](#kinesis-data-analytics-for-sql-applications)
  - [Kinesis Data Analytics for Apache Flink](#kinesis-data-analytics-for-apache-flink)


## Visão Geral

Ferramenta para trabalhar com stream de dados real time.

## Estimativa de custos

- [Calculadora 10 milhões msgs mês](https://calculator.aws/#/estimate?id=5c17b5225b69727b57e8303185865bfb7211bec5).
- [Calculadora 100 milhões msgs mês](https://calculator.aws/#/estimate?id=d2fe61263e7fed9db30742b7c458ef08bf2bfec2).

## Kinesis Data Streams

Serviço para processamento de dados em tempo real.  
Semelhante ao Kafka.

- Provisionamento prévio do cluster
- Cluster é divido em shards
- O dado é dividido nos shards
- **Produtores:**
  - Inputs: Aplicações, estações de trabalho (pc/mobile/etc), SDKs, Kinesis Agent
  - Estrutura da mensagem:
    - Partition Key
    - Data blob (Até 1 Mb)
  - Cada shard recebe 1 MB/sec ou 1.000 msg/sec
  - Partition key direciona dado ao shard
  - Cuidado na seleção da partition key, se haver uma "hot key" (muito mais acesso que o normal), você pode receber "ProvisionedThroughputExceeded"
- **Consumidores:**
  - Outputs: Aplicações, Lambdas, Kinesis Data Firehose, Kinesis Data Analytics
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
      - Limite 2 MB/sec por consumidor e por shard
      - O consumidor faz o subscribe no shard pela nova api "SubscribeToShard()"
      - Latency ~70 ms
      - Maior custo
      - Soft limit de 5 consumer application por stream
  - Necessário informar shard id em libraries/cli de baixo nível
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
- KCL: Library Java que trablha com uma tabela no DynamoDB para compartilhar progresso da leitura dos shards
- Shard Spliting
  - Operação para dividir um shard em dois (Não é permitido mais de 2 na mesma operação)
  - Será criado dois novos shards com os dados divididos e o shard antigo será deletado quando os dados expirarem
  - Não há rotina para escala automatica (Apenas manualmente para cima/baixo e pela api)
- Merging shards
  - Operação para unir dois shards (Somente dois shards por operação)
  - Será criado um novo shard com os dados unificados e os shards antigos serão deletados quando os dados expirarem

## Kinesis Data Firehose

Serviço para processamento de dados Near Real Time.

- Fully Managed Service: Sem administração, automatica scaling e serveless
- Estrutura do serviço:
  - Input (produtores): Aplicações, estações de trabalho (pc/mobile/etc), SDKs, Kinesis Agent, Kinesis Data Stream, Amazon CloudWatch (Logs & Events), AWS IoT
    - Até 1 Mb
  - Tranformation: Lambda function
  - Output: Batch writes
    - AWS: Redshifth, Amazon S3, OpenSearch
    - 3rd party: Splunk, MongoDB, DataDog, NewRelic, etc...
    - Custom: HTTP endpoint
- Latência: No mínimo 60 segundos de 1 Mb de dados (Configurado no destination settings do Delivery Stream)
- Pago por uso
- Não é possível reprocessar mensagens (Não há armazenamento histórico)

## Kinesis Data Analytics

- Dois modelos: Para bases SQL e Apache Flink

### Kinesis Data Analytics for SQL Applications

- Real-time analytics
- Fully managed (Não há servidores para gerenciar)
- Pago por taxa de consumo
- Sources
  - Kinesis Data Streams
  - Kinesis Data Firehose
- Transform
  - SQL statements
  - S3 data
- Outputs
  - Kinesis Data Streams
  - Kinesis Data Firehose


### Kinesis Data Analytics for Apache Flink

- Usa Flink (Java, Scala ou SQL) para processar e analisar o streming de dados
- Flink são aplicações que você precisa codificar
- Sources:
  - Kinesis Data Streams
  - Amazon MSK
- Executa o Apache flink em custos gerenciado na AWS
  - Provisionar recursos computacionais, paralelismo e auto scaling
  - Application backes (Checkpoint e snapshot)
  - Não suportar input de Firehose