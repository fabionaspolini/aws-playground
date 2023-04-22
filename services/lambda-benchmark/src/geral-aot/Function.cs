using System.Collections.Concurrent;
using System.Data.Common;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Dapper;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Logging.Configuration;
using Microsoft.Extensions.Options;
using Npgsql;
using Refit;

namespace Geral.Aot;

public class SampleConfiguration
{
    public string ConnectionString { get; set; } = default!;
}

public class Function
{
    private static readonly IServiceProvider ServiceProvider;

    // AddSimpleConsole() e AddConsole() não funcionam no  build AOT. Trata a aplicação ao receber retorno do refit.
    /*static void ConfigureLogging(ILoggingBuilder builder) => builder
        .AddSimpleConsole(x =>
        {
            x.SingleLine = true;
            x.TimestampFormat = null;
        });*/
    static void ConfigureLogging(ILoggingBuilder builder) => builder.AddMyConsoleLogger();
    // static void ConfigureLogging(ILoggingBuilder builder) { }

    private static async Task Main()
    {
        Func<SampleRequest, ILambdaContext, Task<SampleResponse[]>> handler = FunctionHandlerAsync;
        await LambdaBootstrapBuilder.Create(handler, new SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>())
            .Build()
            .RunAsync();
    }

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
                config.BaseAddress = new Uri(@"https://viacep.com.br");
            });
        // services.AddSingleton<JsonSerializerOptions>(LambdaFunctionJsonSerializerContext.Default.Options);
        ServiceProvider = services.BuildServiceProvider();
    }

    public static async Task<SampleResponse[]> FunctionHandlerAsync(SampleRequest request, ILambdaContext context)
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
                _logger.LogInformation($"{result.cep}, {result.localidade}, {result.bairro}");
            return result;
        }
        catch (Exception e)
        {
            _logger.LogCritical(e, "Erro ao consultar CEP");
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

// Logger


public sealed class MyConsoleLoggerConfiguration
{
    public int EventId { get; set; }
}

public sealed class MyConsoleLogger : ILogger
{
    private readonly string _name;
    private readonly Func<MyConsoleLoggerConfiguration> _getCurrentConfig;

    public MyConsoleLogger(
        string name,
        Func<MyConsoleLoggerConfiguration> getCurrentConfig) =>
        (_name, _getCurrentConfig) = (name, getCurrentConfig);

    public IDisposable? BeginScope<TState>(TState state) where TState : notnull => default!;

    public bool IsEnabled(Microsoft.Extensions.Logging.LogLevel logLevel) => true;

    public void Log<TState>(
        Microsoft.Extensions.Logging.LogLevel logLevel,
        EventId eventId,
        TState state,
        Exception? exception,
        Func<TState, Exception?, string> formatter)
    {
        if (!IsEnabled(logLevel))
        {
            return;
        }

        MyConsoleLoggerConfiguration config = _getCurrentConfig();
        if (config.EventId == 0 || config.EventId == eventId.Id)
            Console.WriteLine($"{formatter(state, exception)}");
    }
}

public sealed class MyConsoleLoggerProvider : ILoggerProvider
{
    private readonly IDisposable? _onChangeToken;
    private MyConsoleLoggerConfiguration _currentConfig;
    private readonly ConcurrentDictionary<string, MyConsoleLogger> _loggers =
        new(StringComparer.OrdinalIgnoreCase);

    public MyConsoleLoggerProvider(
        IOptionsMonitor<MyConsoleLoggerConfiguration> config)
    {
        _currentConfig = config.CurrentValue;
        _onChangeToken = config.OnChange(updatedConfig => _currentConfig = updatedConfig);
    }

    public ILogger CreateLogger(string categoryName) =>
        _loggers.GetOrAdd(categoryName, name => new MyConsoleLogger(name, GetCurrentConfig));

    private MyConsoleLoggerConfiguration GetCurrentConfig() => _currentConfig;

    public void Dispose()
    {
        _loggers.Clear();
        _onChangeToken?.Dispose();
    }
}

public static class MyConsoleLoggerExtensions
{
    public static ILoggingBuilder AddMyConsoleLogger(
        this ILoggingBuilder builder)
    {
        builder.AddConfiguration();

        builder.Services.TryAddEnumerable(
            ServiceDescriptor.Singleton<ILoggerProvider, MyConsoleLoggerProvider>());

        LoggerProviderOptions.RegisterProviderOptions
            <MyConsoleLoggerConfiguration, MyConsoleLoggerProvider>(builder.Services);

        return builder;
    }

    public static ILoggingBuilder AddMyConsoleLogger(
        this ILoggingBuilder builder,
        Action<MyConsoleLoggerConfiguration> configure)
    {
        builder.AddMyConsoleLogger();
        builder.Services.Configure(configure);

        return builder;
    }
}