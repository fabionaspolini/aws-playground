using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.Serialization.SystemTextJson;
using DataAccess.Jit;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

[assembly: LambdaSerializer(typeof(SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>))]

namespace DataAccess.Jit;

public class Function
{
    private static readonly IServiceProvider ServiceProvider;

    static void ConfigureLogging(ILoggingBuilder builder) => builder
        .AddSimpleConsole(x =>
        {
            x.SingleLine = true;
            x.TimestampFormat = null;
        });

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
        logger.LogInformation($"ConnectionString: ${connectionString}");

        services.AddDbContext<SampleContext>(opts => opts.UseNpgsql(connectionString));
        services.AddScoped<SampleUseCase>();
        ServiceProvider = services.BuildServiceProvider();
    }

#pragma warning disable CA1822 // Método sem referência passível de virar static
    public async Task<SampleResponse[]> FunctionHandler(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando");
        var result = new List<SampleResponse>();
        for (var i = 1; i <= request.Count; i++)
        {
            using var scope = ServiceProvider.CreateScope();
            var useCase = scope.ServiceProvider.GetRequiredService<SampleUseCase>();
            await useCase.ExecuteAsync();
        }
        context.Logger.LogInformation("Concluído");
        return result.ToArray();
    }
#pragma warning restore CA1822
}

[JsonSerializable(typeof(SampleRequest))]
[JsonSerializable(typeof(SampleResponse[]))]
public partial class LambdaFunctionJsonSerializerContext : JsonSerializerContext
{
}

#pragma warning disable SYSLIB1037 // Source generator deserialization
public record class SampleRequest(PersonRequest? Person, MathRequest? Math, int Count = 1, bool AddAllResponses = true);
public record class PersonRequest(string FirstName, string LastName);
public record class MathRequest(double A, double B);

public record class SampleResponse(PersonResponse? Person, MathResponse? Math);
public record class PersonResponse(string FullName, string WelcomeMessage);
public record class MathResponse(double C);
#pragma warning restore SYSLIB1037

public class SampleUseCase
{
    private readonly ILogger<SampleUseCase> _logger;
    private readonly SampleContext _context;

    public SampleUseCase(ILogger<SampleUseCase> logger, SampleContext context)
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