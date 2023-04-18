using System.Data.Common;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Dapper;
using Npgsql;

namespace DapperAot.Aot;

public class Function
{
    private static async Task Main()
    {
        Func<SampleRequest, ILambdaContext, Task<SampleResponse[]>> handler = FunctionHandlerAsync;
        await LambdaBootstrapBuilder.Create(handler, new SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>())
            .Build()
            .RunAsync();
    }

    public static async Task<SampleResponse[]> FunctionHandlerAsync(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando Dapper.Aot AOT");
        var result = new List<SampleResponse>();
        for (var i = 1; i <= request.Count; i++)
        {
            var useCase = new SampleUseCase();
            var pessoa = await useCase.ExecuteAsync();
            if (i == 1 || request.AddAllResponses)
                result.Add(new(pessoa));
        }
        context.Logger.LogInformation("Concluído");
        return result.ToArray();
    }
}

[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(SampleResponse[]))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning disable SYSLIB1037 // Source generator deserialization
public record class SampleRequest(int Count = 1, bool AddAllResponses = false);
public record class SampleResponse(PessoaEntity? pessoas);
#pragma warning restore SYSLIB1037

public partial class SampleUseCase
{
    public async Task<PessoaEntity?> ExecuteAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionString");
        using var conn = new NpgsqlConnection(connectionString);
        var pessoas = await GetPessoasAsync(conn);
        foreach (var pessoa in pessoas)
            Console.WriteLine($"{pessoa.id}, {pessoa.nome}, {pessoa.data_nascimento:dd/MM/yyyy}");
        return pessoas.FirstOrDefault();
    }

    [Command("select * from pessoa")]
    public static partial Task<List<PessoaEntity>> GetPessoasAsync(DbConnection connection);
}

public class PessoaEntity
{
    public Guid id { get; set; }
    public string nome { get; set; } = null!;
    public DateTime data_nascimento { get; set; }
}