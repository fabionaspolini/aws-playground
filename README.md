# AWS Playground

## Pré requisitos

1. Conta AWS previamente criada
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado em seu computador
3. [Access Key e Secret Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) geradas para configurar o profile default do CLI
3. CLI configurada para sua account (Executar `aws configure` no terminal)

Nenhum exemplo possui as credenciais de acesso a account AWS, isso é obtido do profile default configurado no passo 3.

Por convenção quando não informado os parâmetros de acesso a account AWS, as bibliotecas utilizam as credenciais configurada nas variáveis de ambiente ou o profile default (Arquivo *~./.aws/credentials*).

## DynamoDB

```bash
aws dynamodb put-item \
    --table-name Venda \
    --item "file://infra/dynamodb/sample.json"

aws dynamodb update-item \
    --table-name Venda \
    --key '{ "Id": { "S": "3c95c725-275c-474a-a068-151f8219f294"}, "DataCadastro": { "S": "2023-04-03T00:43:00.000Z" } }' \
    --update-expression "SET #cliente.#nome = :newval" \
    --expression-attribute-names '{"#cliente": "Cliente", "#nome": "Nome"}' \
    --expression-attribute-values '{":newval":{"S":"Fulano de tal"}}' \
    --return-values ALL_NEW
```