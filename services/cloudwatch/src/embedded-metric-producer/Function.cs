using Amazon.CloudWatch.EMF.Logger;
using Amazon.CloudWatch.EMF.Model;
using Amazon.Lambda.Core;

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
        logger.SetNamespace("MyCustomMetric");
        var dimensionSet = new DimensionSet();
        dimensionSet.AddDimension("By Resource Name", context.FunctionName);
        logger.SetDimensions(dimensionSet);
        logger.PutMetric("Executions", 1, Unit.COUNT);
        logger.PutMetric("InputsConvertidos", result != input ? 1 : 0, Unit.COUNT);
        logger.PutMetric("InputsNaoConvertidos", result == input ? 1 : 0, Unit.COUNT);

        // Environment.GetEnvironmentVariable("AWS_LAMBDA_FUNCTION_NAME")

        return result;
    }
}

#pragma warning restore CA1822