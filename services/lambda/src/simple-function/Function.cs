using Amazon.Lambda.Core;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace SimpleFunction;

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
        context.Logger.LogInformation("Exemplo simples de uma função lambda que converter os caracteres para maiúsculo.");
        return input.ToUpper();
    }
}

#pragma warning restore CA1822