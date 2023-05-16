using System.IO;
using System.Text;
using Amazon.Lambda.Core;

// Assembly attribute to enable the Lambda function's JSON input to be converted into a .NET class.
[assembly: LambdaSerializer(typeof(Amazon.Lambda.Serialization.SystemTextJson.DefaultLambdaJsonSerializer))]

namespace TmpFileSystemPlayground;

#pragma warning disable CA1822 // Warning para marcar método FunctionHandler como estático

// Função mais simples possível, somente o básico `dotnet new lambda.EmptyFunction --name MyFunction`

public class Function
{
    /// <summary>
    /// Função simples, sem nenhum processamento. Serve para comparar o tempo de startup e runtime com outras funções a medida que são incluidas biliotecas e processos.
    /// </summary>
    /// <param name="request"></param>
    /// <param name="context"></param>
    /// <returns></returns>
    public string[] FunctionHandler(FileRequest request, ILambdaContext context)
    {
        if (!string.IsNullOrWhiteSpace(request.Name))
        {
            var sb = new StringBuilder("teste");
            using var file = new StreamWriter("/tmp/" + request.Name, true);
            file.Write(sb);
        }
        var arquivos = Directory.GetFiles("/tmp");
        return arquivos;
    }
}

#pragma warning restore CA1822

public record FileRequest(string Name);