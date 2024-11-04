# S3

- [Visão geral](#visão-geral)
- [Events](#events)

## Visão geral

Por padrão bucket são criados privados.


## Acesso público

1. Desativar opção "Block public access".
2. Em "Object OwnershipInfo", ativar "ACLs" e selecionar "Bucket owner preferred".
3. Ao realizar upload do arquivo, deve-se informar o acl do arquivo como "public-read".

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
