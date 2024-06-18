using Amazon.CloudWatch.EMF.Logger;
using Amazon.CloudWatch.EMF.Model;
using Amazon.Lambda.Core;
using System.Text.Json;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace EmbeddedMetricProducer;

#pragma warning disable CA1822 // Warning para marcar método FunctionHandler como estático

// Função mais simples possível, somente o básico `dotnet new lambda.EmptyFunction --name MyFunction`

public class Function
{
    /// <summary>
    /// Função simples, sem nenhum processamento. Serve para comparar o tempo de startup e runtime com outras funções a medida que são incluidas biliotecas e processos.
    /// </summary>
    /// <param name="input"></param>
    /// <param name="context"></param>
    /// <returns></returns>
    public string FunctionHandler(string input, ILambdaContext context)
    {
        context.Logger.LogInformation("Exemplo simples de uma função lambda para converter os caracteres para maiúsculo.");

        var result = input.ToUpper();

        using var logger = new MetricsLogger();
        logger.SetNamespace("MyCustomMetric.Library");
        var dimensionSet = new DimensionSet();
        dimensionSet.AddDimension("By Resource Name", context.FunctionName);
        logger.SetDimensions(dimensionSet);
        logger.PutMetric("Executions", 1, Unit.COUNT);
        logger.PutMetric("InputsConvertidos", result != input ? 1 : 0, Unit.COUNT);
        logger.PutMetric("InputsNaoConvertidos", result == input ? 1 : 0, Unit.COUNT);

        // Environment.GetEnvironmentVariable("AWS_LAMBDA_FUNCTION_NAME")

        WriteJsonAtConsole();

        return result;
    }

    private void WriteJsonAtConsole()
    {
        var time = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        // 1718729497003
        var statistic = """
                        {
                            "_aws": {
                                "Timestamp": 1718729497003,
                                "CloudWatchMetrics": [
                                    {
                                        "Namespace": "MyCustomMetric.Manual",
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
                    """;
        var json = JsonSerializer.Deserialize<JsonDocument>(statistic.Replace("1718729497003", time.ToString()));
        var jsonMinified = JsonSerializer.Serialize(json, new JsonSerializerOptions { WriteIndented = false });
        Console.WriteLine(jsonMinified);
    }
}

#pragma warning restore CA1822