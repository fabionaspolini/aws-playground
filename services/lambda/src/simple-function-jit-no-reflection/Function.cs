// using System.Collections;
// using System.Text.Json;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using SimpleFunctionJitNoReflection;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
// [assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))] // Default com serialização utilizando reflection
[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))] // Source generator para não usar reflection na serialização dos objetos e melhorar performance

namespace SimpleFunctionJitNoReflection;

#pragma warning disable CA1822 // Warning para marcar método FunctionHandler como estático

// Função mais simples possível, somente o básico `dotnet new lambda.EmptyFunction --name MyFunction` e adicionar o source generator para não haver reflection e comparar de igual para igual com aot

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
        context.Logger.LogInformation("Exemplo simples de uma função lambda que converter os caracteres para maiúsculo.");
        return input.ToUpper();
    }
}

#pragma warning restore CA1822

/// <summary>
/// This class is used to register the input event and return type for the FunctionHandler method with the System.Text.Json source generator.
/// There must be a JsonSerializable attribute for each type used as the input and return type or a runtime error will occur
/// from the JSON serializer unable to find the serialization information for unknown types.
/// </summary>
[JsonSerializable(typeof(string))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
    // By using this partial class derived from JsonSerializerContext, we can generate reflection free JSON Serializer code at compile time
    // which can deserialize our class and properties. However, we must attribute this class to tell it what types to generate serialization code for.
    // See https://docs.microsoft.com/en-us/dotnet/standard/serialization/system-text-json-source-generation
}