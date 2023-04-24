using Dapper;
using RdsBenchmark;
using static System.Console;

WriteLine(".:: RDS Benchmark ::.");

const int Threads = 15;

var parameters = await DatabaseParametersFactory.GetPostgreSqlParametersAsync();
// var parameters = await DatabaseParametersFactory.GetMySqlParametersAsync();

var tasks = new Task[Threads];
for (var i = 0; i < Threads; i++)
    tasks[i] = StartReaderTaskAsync(parameters, i);

Task.WaitAll(tasks);


async static Task StartReaderTaskAsync(DatabaseParameters parameters, int index)
{
    var conn = parameters.CreateConnection(@readonly: true);
    await conn.OpenAsync();
    for (var i = 0; i < 10_000; i++)
    {
        var data = await conn.QueryAsync<Pessoa>("select * from pessoa");
        if (i > 0 && i % 5 == 0)
            WriteLine($"{DateTime.Now:HH:mm:ss.fff} [{index}] i: {i} - count: {data.Count()}");
    }
}

public record class Pessoa(Guid id, string nome, DateTime data_nascimento);