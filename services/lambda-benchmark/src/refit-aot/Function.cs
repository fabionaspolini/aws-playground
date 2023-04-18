using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Refit;

namespace Refit.Aot;

public class Function
{
    private static async Task Main()
    {
        Func<SampleRequest, ILambdaContext, Task<CepResponse>> handler = FunctionHandlerAsync;
        await LambdaBootstrapBuilder.Create(handler, new SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>())
            .Build()
            .RunAsync();
    }

    public static async Task<CepResponse> FunctionHandlerAsync(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando Refit AOT");
        var useCase = new SampleUseCase();
        var response = await useCase.ExecuteAsync(request.Cep);
        context.Logger.LogInformation("Concluído");
        return response;
    }
}

[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(CepResponse))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning disable SYSLIB1037 // Source generator deserialization
public record class SampleRequest(string Cep, int Count = 1, bool AddAllResponses = false);
#pragma warning restore SYSLIB1037

public class SampleUseCase
{
    public async Task<CepResponse?> ExecuteAsync(string cep)
    {
        var baseUrl = @"https://viacep.com.br";
        var client = RestService.For<IViaCepApi>(baseUrl);
        var result = await client.GetCepAsync(cep);
        if (result != null)
            Console.WriteLine($"{result.cep}, {result.localidade}, {result.bairro}");
        return result;
    }
}

public class CepResponse
{
    public string cep { get; set; }
    public string logradouro { get; set; }
    public string complemento { get; set; }
    public string bairro { get; set; }
    public string localidade { get; set; }
    public string uf { get; set; }
    public string ibge { get; set; }
    public string gia { get; set; }
    public string ddd { get; set; }
    public string siafi { get; set; }
}


public interface IViaCepApi
{
    [Get("/ws/{cep}/json")]
    public Task<CepResponse> GetCepAsync(string cep);
}