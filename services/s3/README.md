# S3

- [Visão geral](#visão-geral)
- [Events](#events)

## Visão geral


## Events

- Executar ação quando houver alterações de arquivos (Create, Removed, Restore, etc...)
- Pode filtar (Ex.: *.jpg)
- Geralmente executa em segundos, mas em alguns casos pode demorar um minuto ou mais
- Se duas gravaçoes ocorrerem um arquivo não versionado ao mesmo tempo, é possível que seja executada apenas uma ação de evento
- Targets
  - SNS, SQS ou Lambda Function
  - S3 -> SNS -> SQS
  - S3 -> SQS -> Lambda Function
  - S3 -> Lambda Funcion (async invocation) -> DLQ SQS