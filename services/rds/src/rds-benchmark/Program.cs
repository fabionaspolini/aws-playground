using Amazon;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using Amazon.SimpleSystemsManagement;
using Amazon.SimpleSystemsManagement.Model;
using Dapper;
using Npgsql;
using static System.Console;

WriteLine(".:: RDS Benchmark ::.");

var secretClient = new AmazonSecretsManagerClient(RegionEndpoint.USEast1);
var ssmClient = new AmazonSimpleSystemsManagementClient(RegionEndpoint.USEast1);

var usernameSecret = await secretClient.GetSecretValueAsync(new GetSecretValueRequest { SecretId = "aurora-postgresql-sample-username" });
var passwordSecret = await secretClient.GetSecretValueAsync(new GetSecretValueRequest { SecretId = "aurora-postgresql-sample-password" });
var endpointParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = "aurora-postgresql-sample-endpoint" });
var readerEndpointParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = "aurora-postgresql-sample-reader-endpoint" });
var portParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = "	aurora-postgresql-sample-port" });
var databaseNameParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = "	aurora-postgresql-sample-database-name" });

var username = usernameSecret.SecretString;
var password = passwordSecret.SecretString;
var endpoint = endpointParamter.Parameter.Value;
var readerEndpoint = readerEndpointParamter.Parameter.Value;
var port = portParamter.Parameter.Value;
var databaseName = databaseNameParamter.Parameter.Value;

var connectionString = $"Server={endpoint};Port={port};Database={databaseName};User Id={username};Password={password};";
var readerConnectionString = $"Server={readerEndpoint};Port={port};Database={databaseName};User Id={username};Password={password};";

var conn = new NpgsqlConnection(connectionString);
await conn.OpenAsync();
for (var i = 0; i < 500_000; i++)
{
    var data = await conn.QueryAsync<Pessoa>("select * from pessoa");
    if (i > 0 && i % 5 == 0)
        WriteLine($"{DateTime.Now:HH:mm:ss.fff} i: {i} - count: {data.Count()}");
}


public record class Pessoa(Guid id, string nome, DateTime data_nascimento);