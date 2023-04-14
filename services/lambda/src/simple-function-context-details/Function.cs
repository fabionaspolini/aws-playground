using System.Collections;
using System.Text.Json;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using Amazon.XRay.Recorder.Core;
using Amazon.XRay.Recorder.Handlers.AwsSdk;
using SimpleFunctionContextDetails;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
// [assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))] // Default com serialização utilizando reflection
[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))] // Source generator para não usar reflection na serialização dos objetos e melhorar performance

namespace SimpleFunctionContextDetails;

#pragma warning disable CA1822 // Warning para marcar método FunctionHandler como estático

public class Function
{
    public Function()
    {
        AWSSDKHandler.RegisterXRayForAllServices();
    }

    /// <summary>
    /// A simple function that takes a string and does a ToUpper
    /// </summary>
    /// <param name="request"></param>
    /// <param name="context"></param>
    /// <returns></returns>
    public SampleResponse FunctionHandler(SampleRequest request, ILambdaContext context)
    {
        AWSXRayRecorder.Instance.AddAnnotation("minha annotation", "my value"); // Não aparece no console
        AWSXRayRecorder.Instance.AddMetadata("meu metadata", "my value"); // Não aparece no console

        context.Logger.LogInformation("Exemplo simples de uma função lambda que converter os caracteres para maiúsculo.");
        context.Logger.LogInformation($"Input: {JsonSerializer.Serialize(request, LambdaFunctionJsonSerializerContext.Default.SampleRequest)}");
        context.Logger.LogInformation($">>>>> CONTEXT DATA <<<<<");

        // Exemplo simples para imprimir todas as variáveis de contexto. Na prática é ruim pois usa reflection
        AWSXRayRecorder.Instance.BeginSubsegment("Iniciando log de informações do contexto");
        try
        {
            var properties = context.GetType().GetProperties().ToDictionary(x => x.Name, x => x.GetValue(context));
            foreach (var (key, value) in properties)
                context.Logger.LogInformation($"{key}: {value}");
            context.Logger.LogInformation($"context.Identity.IdentityId: {context.Identity?.IdentityId}");
        }
        finally
        {
            AWSXRayRecorder.Instance.EndSubsegment();
        }

        AWSXRayRecorder.Instance.BeginSubsegment("Iniciando log de variáveis de ambiente");
        try
        {
            var environments = Environment.GetEnvironmentVariables().Cast<DictionaryEntry>();
            context.Logger.LogInformation(new string('-', 80));

            context.Logger.LogInformation($">>>>> ENVIRONMENT VARIABLES <<<<< ");
            foreach (var (key, value) in environments)
                context.Logger.LogInformation($"{key}: {value}");

            AWSXRayRecorder.Instance.AddAnnotation("minha annotation env", "my value"); // Não aparece no console
            AWSXRayRecorder.Instance.AddMetadata("meu metadata env", "my value"); // Aparece no subsegment relacionado as vaira´veis de ambiente
        }
        finally
        {
            AWSXRayRecorder.Instance.EndSubsegment();
        }

        if (request.Sleep.HasValue)
        {
            AWSXRayRecorder.Instance.BeginSubsegment("sleep");
            Thread.Sleep(request.Sleep.Value);
            AWSXRayRecorder.Instance.EndSubsegment();
        }

        context.Logger.LogInformation("====== FIM ======");
        return new SampleResponse
        {
            Text = request.TextToUpper?.ToUpper()
        };
    }
}

public class SampleRequest
{
    public string? TextToUpper { get; set; }
    public string? BuscarCep { get; set; }
    public int? Sleep { get; set; }
}

public class SampleResponse
{
    public string? Text { get; set; }
    public string? CepInfo { get; set; }
}

/// <summary>
/// Source generator para não usar reflection na serialização dos objetos e melhorar performance
/// </summary>
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(SampleResponse))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning restore CA1822