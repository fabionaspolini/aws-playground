# CloudWatch

## Embedded metrics

- [Documentação AWS](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch_Embedded_Metric_Format_Specification.html).
- [Library C# - Amazon.CloudWatch.EMF](https://github.com/awslabs/aws-embedded-metrics-dotnet)

## Amazon.CloudWatch.EMF

Biblioteca .NET para geração de métricas personalizadas.

**Dependências:**

- Não possui dependência com AWSSDK
- Newtonsoft.Json
- Microsoft.Extensions.Logging.Abstractions
- Ela envia para API do CloudWatch Metrics, e depende do cloud watch agent rodando no ambiente.


## Exemplos

JSON gerado pela métrica.

```json
{
    "_aws": {
        "Timestamp": 1718729497003,
        "CloudWatchMetrics": [
            {
                "Namespace": "MyCustomMetric",
                "Metrics": [
                    {
                        "Name": "Executions",
                        "Unit": "Count"
                    },
                    {
                        "Name": "InputsConvertidos",
                        "Unit": "Count"
                    },
                    {
                        "Name": "InputsNaoConvertidos",
                        "Unit": "Count"
                    }
                ],
                "Dimensions": [
                    [
                        "By Resource Name"
                    ]
                ]
            }
        ]
    },
    "executionEnvironment": "AWS_DOTNET_LAMDBA_TEST_TOOL_BLAZOR_0.15.1",
    "By Resource Name": "EmbeddedMetricProducer::EmbeddedMetricProducer.Function::FunctionHandler",
    "Executions": 1.0,
    "InputsConvertidos": 1.0,
    "InputsNaoConvertidos": 0.0
}
```