# DynamoDB

Exemplo de utilização pela CLI.

```bash
cd infra/dynamodb

aws dynamodb create-table \
    --table-name Venda \
    --attribute-definitions \
        AttributeName=AnoMes,AttributeType=S \
        AttributeName=Id,AttributeType=S \
    --key-schema AttributeName=AnoMes,KeyType=HASH AttributeName=Id,KeyType=RANGE \
    --table-class STANDARD \
    --billing-mode PAY_PER_REQUEST \
    --endpoint-url http://localhost:8000

aws dynamodb put-item \
    --table-name Venda \
    --item "file://sample-put.json" \
    --endpoint-url http://localhost:8000

aws dynamodb update-item \
    --table-name Venda \
    --key '{ "Id": { "S": "3c95c725-275c-474a-a068-151f8219f294"}, "AnoMes": { "S": "2023-04" } }' \
    --update-expression "SET #cliente.#nome = :newval" \
    --expression-attribute-names '{"#cliente": "Cliente", "#nome": "Nome"}' \
    --expression-attribute-values '{":newval":{"S":"Beltrano"}}'
```

## DynamoDB local

Subir serviço pelo Docker.

```bash
docker run --name dynamodb -d -p 8000:8000 amazon/dynamodb-local
```

Utilizar o parâmetro `--endpoint-url http://localhost:8000` para direcionar comando ao ambiente local.
