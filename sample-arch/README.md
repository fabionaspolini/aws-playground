
## Subscription filter

O api gateway possui logs de acesso habilitado, e são replicado no S3 para posterior utilização pelo Athena.

Pipeline de dados: `API Gateway > Log Group > Subscription Filter > Kinesis Firehose > S3 (gzip)`.

[Fonte](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/SubscriptionFilters.html#FirehoseExample).
