using System.Collections;
using System.Text.Json;
using Amazon.Lambda.Core;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace SimpleFunctionContextDetails;

#pragma warning disable CA1822 // Warning para marcar método FunctionHandler como estático

public class Function
{
    /// <summary>
    /// A simple function that takes a string and does a ToUpper
    /// </summary>
    /// <param name="input"></param>
    /// <param name="context"></param>
    /// <returns></returns>
    public string FunctionHandler(string input, ILambdaContext context)
    {
        context.Logger.LogInformation("Exemplo simples de uma função lambda que converter os caracteres para maiúsculo.");
        context.Logger.LogInformation($"Input: {input}");
        context.Logger.LogInformation($">>>>> CONTEXT DATA <<<<<");

        // Exemplo simples para imprimir todas as variáveis de contexto. Na prática é ruim pois usa reflection
        var properties = context.GetType().GetProperties().ToDictionary(x => x.Name, x => x.GetValue(context));
        foreach (var (key, value) in properties)
            context.Logger.LogInformation($"{key}: {value}");
        context.Logger.LogInformation($"context.Identity.IdentityId: {context.Identity?.IdentityId}");

        var environments = Environment.GetEnvironmentVariables().Cast<DictionaryEntry>();
        context.Logger.LogInformation(new string('-', 80));

        context.Logger.LogInformation($">>>>> ENVIRONMENT VARIABLES <<<<< ");
        foreach (var (key, value) in environments)
            context.Logger.LogInformation($"{key}: {value}");

        context.Logger.LogInformation("====== FIM ======");
        return input.ToUpper();
    }
}

#pragma warning restore CA1822