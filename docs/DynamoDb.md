# DynamoDB

Exemplo de utilização pela CLI.

```bash
cd infra/dynamodb

aws dynamodb put-item \
    --table-name Venda \
    --item "file://sample-put.json"

aws dynamodb update-item \
    --table-name Venda \
    --key '{ "Id": { "S": "3c95c725-275c-474a-a068-151f8219f294"}, "AnoMes": { "S": "2023-04" } }' \
    --update-expression "SET #cliente.#nome = :newval" \
    --expression-attribute-names '{"#cliente": "Cliente", "#nome": "Nome"}' \
    --expression-attribute-values '{":newval":{"S":"Beltrano"}}'
```