using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using StringUpperCase;
using System.Text.Json.Serialization;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
// [assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]
[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))]

namespace StringUpperCase;

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
    public InputResponse FunctionHandler(InputRequest input, ILambdaContext context)
    {
        context.Logger.LogInformation("Exemplo simples de uma função lambda para converter os caracteres para maiúsculo.");
        return new InputResponse(input.Value.ToUpper());
    }
}

public record class InputRequest(string Value);
public record class InputResponse(string Value);

/// <summary>
/// Source generator para não usar reflection na serialização dos objetos e melhorar performance
/// </summary>
[JsonSourceGenerationOptions(PropertyNamingPolicy = JsonKnownNamingPolicy.CamelCase)]
[JsonSerializable(typeof(InputRequest))]
[JsonSerializable(typeof(InputResponse))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning restore CA1822