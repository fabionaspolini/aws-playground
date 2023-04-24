using System.Data.Common;
using MySqlConnector;
using Npgsql;

namespace RdsBenchmark;

public static class DatabaseConnectionFactory
{
    public static DbConnection CreateConnection(this DatabaseParameters parameters, bool @readonly) => parameters.Engine switch
    {
        DatabaseParamenterEngine.PostgreSql => parameters.CreatePostgreSqlConnection(@readonly),
        DatabaseParamenterEngine.MySql => parameters.CreateMySqlConnection(@readonly),
        _ => throw new ArgumentOutOfRangeException(nameof(parameters.Engine), parameters.Engine, "Valor inválido para obter conexão com o banco de dados.")
    };

    private static NpgsqlConnection CreatePostgreSqlConnection(this DatabaseParameters parameters, bool @readonly)
    {
        var endpoint = @readonly ? parameters.ReaderEndpoint : parameters.Endpoint;
        var connectionString = $"Server={endpoint};Port={parameters.Port};Database={parameters.DatabaseName};User Id={parameters.UserName};Password={parameters.Password};Application Name=RDS Benchmark (aws-playground);";
        var conn = new NpgsqlConnection(connectionString);
        return conn;
    }

    private static MySqlConnection CreateMySqlConnection(this DatabaseParameters parameters, bool @readonly)
    {
        var endpoint = @readonly ? parameters.ReaderEndpoint : parameters.Endpoint;
        var connectionString = $"Server={endpoint};Port={parameters.Port};Database={parameters.DatabaseName};Uid={parameters.UserName};Pwd={parameters.Password};Application Name=RDS Benchmark (aws-playground);";
        var conn = new MySqlConnection(connectionString);
        return conn;
    }
}
