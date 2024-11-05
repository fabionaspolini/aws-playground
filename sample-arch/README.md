
## Subscription filter

O api gateway possui logs de acesso habilitado, e são replicado no S3 para posterior utilização pelo Athena.

Pipeline de dados: `API Gateway > Log Group > Subscription Filter > Kinesis Firehose > S3 (gzip)`.

[Fonte](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html#FirehoseExample).

## Testes

[AWS CLI Command Referente](https://awscli.amazonaws.com/v2/documentation/api/2.8.7/reference/firehose/put-record.html).

```bash
aws firehose put-record \
  --delivery-stream-name "api-gateway-access-logging" \
  --record '{"Data":{ "id": 1, "nome": "Teste" } }'

aws firehose put-record \
  --delivery-stream-name "api-gateway-access-logging" \
  --record '{"Data":"eyAiaWQiOiAxLCAibm9tZSI6ICJUZXN0ZSIgfQ=="}'
```