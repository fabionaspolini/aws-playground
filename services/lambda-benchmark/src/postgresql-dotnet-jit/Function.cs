using System.Data;
using Amazon.Lambda.Core;
using Npgsql;

namespace PostgreSqlLambdaBenchmark.Jit;

public class Function
{
#pragma warning disable CA1822 // Método sem referência passível de virar static
    // Para teste comparando com Python / NodeJS
    public async Task FunctionHandler(ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando PostgreSQL .NET JIT (Teste comparação .NET vs NodeJS vs Python)");
        await PrintPessoasAsync();
        context.Logger.LogInformation("Concluído");
    }
#pragma warning restore CA1822

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
