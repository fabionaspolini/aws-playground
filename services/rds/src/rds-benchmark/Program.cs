using Dapper;
using Dapper.Contrib.Extensions;
using RdsBenchmark;
using static System.Console;

WriteLine(".:: RDS Benchmark ::.");

const int Threads = 1;

// var parameters = await DatabaseParametersFactory.GetPostgreSqlParametersAsync();
var parameters = await DatabaseParametersFactory.GetMySqlParametersAsync();

var tasks = new Task[Threads];
for (var i = 0; i < Threads; i++)
    // tasks[i] = StarReaderTaskAsync(parameters, i);
    tasks[i] = StartWriterTaskAsync(parameters, i);

Task.WaitAll(tasks);


async static Task StarReaderTaskAsync(DatabaseParameters parameters, int index)
{
    var conn = parameters.CreateConnection(ConnectionEndpoint.Reader);
    await conn.OpenAsync();
    for (var i = 0; i < 10_000; i++)
    {
        try
        {
            var data = await conn.QueryAsync<Pessoa>("select * from pessoa");
            if (i > 0 && i % 5 == 0)
                WriteLine($"{DateTime.Now:HH:mm:ss.fff} [select {index}] i: {i} - count: {data.Count()}");
        }
        catch (Exception e)
        {
            WriteLine($"{DateTime.Now:HH:mm:ss.fff} [select {index}] i: {i} - Erro ao consultar dados: {e}");
            throw;
        }
    }
}

async static Task StartWriterTaskAsync(DatabaseParameters parameters, int index)
{
    try
    {
        var conn = parameters.CreateConnection(ConnectionEndpoint.All);
        await conn.OpenAsync();
        for (var i = 0; i < 1_000; i++)
        {
            try
            {
                var pessoa = new Pessoa(
                    id: Guid.NewGuid(),
                    nome: "Teste insert",
                    data_nascimento: DateTime.Now);
                await conn.InsertAsync(pessoa);

                if (i > 0 && i % 5 == 0)
                    WriteLine($"{DateTime.Now:HH:mm:ss.fff} [insert {index}] i: {i}");
            }
            catch (Exception e)
            {
                WriteLine($"{DateTime.Now:HH:mm:ss.fff} [insert {index}] i: {i} - Erro ao inserir dados: {e}");
            }
        }
    }
    catch (Exception e)
    {
        WriteLine($"Erro ao inserir dados: {e}");
        throw;
    }
}

[Table("pessoa")]
public record class Pessoa(
    [property: ExplicitKey] Guid id,
    string nome,
    DateTime data_nascimento);