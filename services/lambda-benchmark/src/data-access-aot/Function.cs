using System.Data.Common;
using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Dapper;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Npgsql;

namespace DataAccess.Aot;

public class SampleConfiguration
{
    public string ConnectionString { get; set; } = default!;
}

public class Function
{
    private static readonly IServiceProvider ServiceProvider;

    static void ConfigureLogging(ILoggingBuilder builder) => builder
        .AddSimpleConsole(x =>
        {
            x.SingleLine = true;
            x.TimestampFormat = null;
        });

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
        services.AddDbContext<SampleContext>(opts => opts.UseNpgsql(connectionString));
        services.AddScoped<SampleUseCaseWithEf>();
        services.AddScoped<SampleUseCaseWithDapper>();
        ServiceProvider = services.BuildServiceProvider();
    }

    public static async Task<SampleResponse[]> FunctionHandlerAsync(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando");
        var result = new List<SampleResponse>();
        for (var i = 1; i <= request.Count; i++)
        {
            using var scope = ServiceProvider.CreateScope();
            if (request.DbEngine == "EF")
            {
                context.Logger.LogInformation("DbEngine: EF");
                var useCase = scope.ServiceProvider.GetRequiredService<SampleUseCaseWithEf>();
                await useCase.ExecuteAsync();
            }
            else
            {
                context.Logger.LogInformation("DbEngine: Dapper");
                var useCase = scope.ServiceProvider.GetRequiredService<SampleUseCaseWithDapper>();
                await useCase.ExecuteAsync();
            }
        }
        context.Logger.LogInformation("Concluído");
        return result.ToArray();
    }
}

[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(SampleResponse[]))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning disable SYSLIB1037 // Source generator deserialization
public record class SampleRequest(
    PersonRequest? Person,
    MathRequest? Math,
    int Count = 1,
    bool AddAllResponses = true,
    string DbEngine = "Dapper");
public record class PersonRequest(string FirstName, string LastName);
public record class MathRequest(double A, double B);

public record class SampleResponse(PersonResponse? Person, MathResponse? Math);
public record class PersonResponse(string FullName, string WelcomeMessage);
public record class MathResponse(double C);
#pragma warning restore SYSLIB1037

public class SampleUseCaseWithEf
{
    private readonly ILogger<SampleUseCaseWithEf> _logger;
    private readonly SampleContext _context;

    public SampleUseCaseWithEf(ILogger<SampleUseCaseWithEf> logger, SampleContext context)
    {
        _context = context;
        _logger = logger;
    }

    public async Task ExecuteAsync()
    {
        var pessoas = await _context.Pessoas.AsNoTracking().ToArrayAsync();
        foreach (var pessoa in pessoas)
            _logger.LogInformation($"{pessoa.Id}, {pessoa.Nome}, {pessoa.DataNascimento:dd/MM/yyyy}");
    }
}

public partial class SampleUseCaseWithDapper
{
    private readonly ILogger<SampleUseCaseWithDapper> _logger;
    private readonly IOptions<SampleConfiguration> _configuration;

    public SampleUseCaseWithDapper(ILogger<SampleUseCaseWithDapper> logger, IOptions<SampleConfiguration> configuration)
    {
        _logger = logger;
        _configuration = configuration;
    }

    public async Task ExecuteAsync()
    {
        _logger.LogInformation($"Connection string in dapper use case: {_configuration.Value.ConnectionString}");
        using var conn = new NpgsqlConnection(_configuration.Value.ConnectionString);
        var pessoas = await GetPessoasAsync(conn);
        foreach (var pessoa in pessoas)
            _logger.LogInformation($"{pessoa.id}, {pessoa.nome}, {pessoa.data_nascimento:dd/MM/yyyy}");
    }

    [Command("select * from pessoa")]
    public static partial Task<List<PessoaDto>> GetPessoasAsync(DbConnection connection);
}

public class SampleContext : DbContext
{
    public SampleContext(DbContextOptions options) : base(options)
    {
    }

    protected SampleContext()
    {
    }

    public DbSet<PessoaEntity> Pessoas { get; set; } = default!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        var pessoaBuilder = modelBuilder.Entity<PessoaEntity>();
        pessoaBuilder.ToTable("pessoa");
        pessoaBuilder.HasKey(x => x.Id);
        pessoaBuilder.Property(x => x.Id).HasColumnName("id");
        pessoaBuilder.Property(x => x.Nome).HasColumnName("nome").HasMaxLength(100);
        pessoaBuilder.Property(x => x.DataNascimento).HasColumnName("data_nascimento");
    }
}

public class PessoaEntity
{
    public Guid Id { get; set; }
    public string Nome { get; set; } = null!;
    public DateTime DataNascimento { get; set; }
}

public class PessoaDto
{
    public Guid id { get; set; }
    public string nome { get; set; } = null!;
    public DateTime data_nascimento { get; set; }
}