using System.Data.Common;
using System.Text.Json;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using Dapper;
using Geral.Jit;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;
using Refit;

[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))]

namespace Geral.Jit;

public class SampleConfiguration
{
    public string ConnectionString { get; set; } = default!;
}

public class Function
{
    private static readonly IServiceProvider ServiceProvider;

    /*static void ConfigureLogging(ILoggingBuilder builder) => builder
        .AddSimpleConsole(x =>
        {
            x.SingleLine = true;
            x.TimestampFormat = null;
        });*/
    static void ConfigureLogging(ILoggingBuilder builder) {}

    static Function()
    {
        var config = new ConfigurationBuilder()
            .AddEnvironmentVariables()
            .Build();

        var loggerFactory = LoggerFactory.Create(ConfigureLogging);
        var logger = loggerFactory.CreateLogger<Function>();

        var services = new ServiceCollection();
        services.AddSingleton(config);
        services.AddSingleton(loggerFactory);
        services.AddLogging(ConfigureLogging);

        var connectionString = config.GetValue<string>("ConnectionString");
        logger.LogInformation($"ConnectionString: {connectionString}");

        services.Configure<SampleConfiguration>(config);
        services.AddScoped<SampleDapperAotUseCase>();
        services.AddScoped<SampleRefitUseCase>();


        var refitSettings = new RefitSettings()
        {
            ContentSerializer = new SystemTextJsonContentSerializer(LambdaFunctionJsonSerializerContext.Default.Options)
        };
        services.AddRefitClient<IViaCepApi>(refitSettings)
            .ConfigureHttpClient(config =>
            {
                Console.WriteLine("CONFIGURANDO REFIT HTTP CLIENT");
                config.BaseAddress = new Uri(@"https://viacep.com.br");
            });
        // services.AddSingleton<JsonSerializerOptions>(LambdaFunctionJsonSerializerContext.Default.Options);
        ServiceProvider = services.BuildServiceProvider();
    }

#pragma warning disable CA1822 // Método sem referência passível de virar static
    public async Task<SampleResponse[]> FunctionHandler(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando Geral JIT");
        var result = new List<SampleResponse>();
        for (var i = 1; i <= request.Count; i++)
        {
            using var scope = ServiceProvider.CreateScope();
            if (request.EnableDapperAot)
            {
                var useCase = scope.ServiceProvider.GetRequiredService<SampleDapperAotUseCase>();
                await useCase.ExecuteAsync();
            }
            if (request.EnableRefit)
            {
                var useCase = scope.ServiceProvider.GetRequiredService<SampleRefitUseCase>();
                await useCase.ExecuteAsync("02739000");
            }
        }
        context.Logger.LogInformation("Concluído");
        return result.ToArray();
    }
#pragma warning restore CA1822
}

[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(SampleResponse[]))]
[JsonSerializable(typeof(CepResponse))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning disable SYSLIB1037 // Source generator deserialization
public record class SampleRequest(
    int Count = 1,
    bool EnableDapperAot = true,
    bool EnableRefit = true);

public record class SampleResponse();
#pragma warning restore SYSLIB1037

// Dapper Aot

public partial class SampleDapperAotUseCase
{
    private readonly ILogger<SampleDapperAotUseCase> _logger;
    private readonly IOptions<SampleConfiguration> _configuration;

    public SampleDapperAotUseCase(ILogger<SampleDapperAotUseCase> logger, IOptions<SampleConfiguration> configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public async Task ExecuteAsync()
    {
        using var conn = new NpgsqlConnection(_configuration.Value.ConnectionString);
        var pessoas = await GetPessoaAsync(conn);
        foreach (var pessoa in pessoas)
            _logger.LogInformation($"{pessoa.id}, {pessoa.nome}, {pessoa.data_nascimento:dd/MM/yyyy}");
    }

    [Command("select * from pessoa")]
    public static partial Task<List<PessoaEntity>> GetPessoaAsync(DbConnection conn);
}


public class PessoaEntity
{
    public Guid id { get; set; }
    public string nome { get; set; } = null!;
    public DateTime data_nascimento { get; set; }
}

// Refit

public class SampleRefitUseCase
{
    private readonly ILogger<SampleRefitUseCase> _logger;
    private readonly IViaCepApi _viaCepApi;

    public SampleRefitUseCase(ILogger<SampleRefitUseCase> logger, IViaCepApi viaCepApi)
    {
        _logger = logger;
        _viaCepApi = viaCepApi;
    }

    public async Task<CepResponse?> ExecuteAsync(string cep)
    {
        try
        {
            var result = await _viaCepApi.GetCepAsync(cep);
            if (result != null)
                _logger?.LogInformation($"{result.cep}, {result.localidade}, {result.bairro}");
            return result;
        }
        catch (Exception e)
        {
            _logger?.LogCritical(e, "Erro ao consultar CEP");
            throw;
        }
    }
}

public class CepResponse
{
    public string cep { get; set; }
    public string logradouro { get; set; }
    public string complemento { get; set; }
    public string bairro { get; set; }
    public string localidade { get; set; }
    public string uf { get; set; }
    public string ibge { get; set; }
    public string gia { get; set; }
    public string ddd { get; set; }
    public string siafi { get; set; }
}


public interface IViaCepApi
{
    [Get("/ws/{cep}/json")]
    public Task<CepResponse> GetCepAsync(string cep);
}
