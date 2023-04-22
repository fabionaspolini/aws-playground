using System.Data;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Npgsql;

namespace PostgreSqlLambdaBenchmark.Aot;

public class Function
{
    private static async Task Main()
    {
        Func<ILambdaContext, Task> handler = FunctionHandlerAsync;
        await LambdaBootstrapBuilder.Create(handler)
            .Build()
            .RunAsync();
    }

    public static async Task FunctionHandlerAsync(ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando PostgreSQL .NET AOT (Teste comparação .NET vs NodeJS vs Python)");
        await PrintPessoasAsync();
        context.Logger.LogInformation("Concluído");
    }

    private static async Task PrintPessoasAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionString");
        using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = "select * from pessoa";
        using var reader = await cmd.ExecuteReaderAsync();

        while (reader.Read())
            Console.WriteLine($"{reader.GetGuid("id")}, {reader.GetString("nome")}, {reader.GetDateTime("data_nascimento"):dd/MM/yyyy}");
    }
}
