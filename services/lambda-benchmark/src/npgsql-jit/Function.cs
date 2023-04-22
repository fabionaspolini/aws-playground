using System.Data;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using Npgsql.Jit;

[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))]

namespace Npgsql.Jit;

public class Function
{
#pragma warning disable CA1822 // Método sem referência passível de virar static
    public async Task<SampleResponse[]> FunctionHandler(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando Npgsql JIT");
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
#pragma warning restore CA1822
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

public class SampleUseCase
{
    public async Task<PessoaEntity?> ExecuteAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionString");
        using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = "select * from pessoa";
        using var reader = await cmd.ExecuteReaderAsync();

        var pessoas = new List<PessoaEntity>();
        while (reader.Read())
        {
            pessoas.Add(new PessoaEntity
            {
                id = reader.GetGuid("id"),
                nome = reader.GetString("nome"),
                data_nascimento = reader.GetDateTime("data_nascimento"),
            });
        }
        foreach (var pessoa in pessoas)
            Console.WriteLine($"{pessoa.id}, {pessoa.nome}, {pessoa.data_nascimento:dd/MM/yyyy}");
        return pessoas.FirstOrDefault();
    }
}

public class PessoaEntity
{
    public Guid id { get; set; }
    public string nome { get; set; } = null!;
    public DateTime data_nascimento { get; set; }
}