using System.Data.Common;
using MySqlConnector;
using Npgsql;

namespace RdsBenchmark;

public enum ConnectionEndpoint
{
    Writer,
    Reader,
    All
}

public static class DatabaseConnectionFactory
{
    public static DbConnection CreateConnection(this DatabaseParameters parameters, ConnectionEndpoint endpoint) => parameters.Engine switch
    {
        DatabaseParamenterEngine.PostgreSql => parameters.CreatePostgreSqlConnection(endpoint),
        DatabaseParamenterEngine.MySql => parameters.CreateMySqlConnection(endpoint),
        _ => throw new ArgumentOutOfRangeException(nameof(parameters.Engine), parameters.Engine, "Valor inválido para obter conexão com o banco de dados.")
    };

    private static NpgsqlConnection CreatePostgreSqlConnection(this DatabaseParameters parameters, ConnectionEndpoint endpoint)
    {
        string server = string.Empty;
        if (endpoint is ConnectionEndpoint.Writer or ConnectionEndpoint.All)
            server = parameters.Endpoint + ",";
        if (endpoint is ConnectionEndpoint.Reader or ConnectionEndpoint.All)
            server = parameters.ReaderEndpoint + ",";
        server = server.TrimEnd(',');

        var connectionString = $"Server={server};Port={parameters.Port};Database={parameters.DatabaseName};User Id={parameters.UserName};Password={parameters.Password};Application Name=RDS Benchmark (aws-playground);";
        var conn = new NpgsqlConnection(connectionString);
        return conn;
    }

    private static MySqlConnection CreateMySqlConnection(this DatabaseParameters parameters, ConnectionEndpoint endpoint)
    {
        string server = string.Empty;
        if (endpoint is ConnectionEndpoint.Writer or ConnectionEndpoint.All)
            server += parameters.Endpoint + ",";
        if (endpoint is ConnectionEndpoint.Reader or ConnectionEndpoint.All)
            server += parameters.ReaderEndpoint + ",";
        server = server.TrimEnd(',');

        var connectionString = $"Server={server};Port={parameters.Port};Database={parameters.DatabaseName};Uid={parameters.UserName};Pwd={parameters.Password};Application Name=RDS Benchmark (aws-playground);";
        var conn = new MySqlConnection(connectionString);
        return conn;
    }
}
