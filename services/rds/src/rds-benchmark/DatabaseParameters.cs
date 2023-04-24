using Amazon;
using Amazon.SecretsManager;
using Amazon.SecretsManager.Model;
using Amazon.SimpleSystemsManagement;
using Amazon.SimpleSystemsManagement.Model;

namespace RdsBenchmark;

public enum DatabaseParamenterEngine
{
    PostgreSql,
    MySql
}

public record class DatabaseParameters(
    DatabaseParamenterEngine Engine,
    string Endpoint,
    string ReaderEndpoint,
    int Port,
    string UserName,
    string Password,
    string DatabaseName);

public class DatabaseParametersFactory
{
    public static async Task<DatabaseParameters> GetParametersAsync(string namePrefix, DatabaseParamenterEngine engine)
    {
        var secretClient = new AmazonSecretsManagerClient(RegionEndpoint.USEast1);
        var ssmClient = new AmazonSimpleSystemsManagementClient(RegionEndpoint.USEast1);

        var usernameSecret = await secretClient.GetSecretValueAsync(new GetSecretValueRequest { SecretId = $"{namePrefix}-username" });
        var passwordSecret = await secretClient.GetSecretValueAsync(new GetSecretValueRequest { SecretId = $"{namePrefix}-password" });
        var endpointParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = $"{namePrefix}-endpoint" });
        var readerEndpointParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = $"{namePrefix}-reader-endpoint" });
        var portParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = $"{namePrefix}-port" });
        var databaseNameParamter = await ssmClient.GetParameterAsync(new GetParameterRequest { Name = $"{namePrefix}-database-name" });

        return new DatabaseParameters(
            Engine: engine,
            Endpoint: endpointParamter.Parameter.Value,
            ReaderEndpoint: readerEndpointParamter.Parameter.Value,
            Port: Convert.ToInt32(portParamter.Parameter.Value),
            UserName: usernameSecret.SecretString,
            Password: passwordSecret.SecretString,
            DatabaseName: databaseNameParamter.Parameter.Value);
    }

    public static Task<DatabaseParameters> GetPostgreSqlParametersAsync() => GetParametersAsync("aurora-postgresql-sample", DatabaseParamenterEngine.PostgreSql);
    public static Task<DatabaseParameters> GetMySqlParametersAsync() => GetParametersAsync("aurora-mysql-sample", DatabaseParamenterEngine.MySql);
}