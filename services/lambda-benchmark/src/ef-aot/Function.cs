using System.Text.Json.Serialization;
using Amazon.Lambda.Core;
using Amazon.Lambda.RuntimeSupport;
using Amazon.Lambda.Serialization.SystemTextJson;
using Ef.Aot;
using Microsoft.EntityFrameworkCore;

namespace Ef.Aot;

public class Function
{
    private static async Task Main()
    {
        Func<SampleRequest, ILambdaContext, Task<SampleResponse[]>> handler = FunctionHandlerAsync;
        await LambdaBootstrapBuilder.Create(handler, new SourceGeneratorLambdaJsonSerializer<LambdaFunctionJsonSerializerContext>())
            .Build()
            .RunAsync();
    }

    public static async Task<SampleResponse[]> FunctionHandlerAsync(SampleRequest request, ILambdaContext context)
    {
        context.Logger.LogInformation("Iniciando");
        var result = new List<SampleResponse>();
        for (var i = 1; i <= request.Count; i++)
        {
            var useCase = new SampleUseCase();
            var pessoa = await useCase.ExecuteAsync();
            if (i == 1 || request.AddAllResponses)
                result.Add(new(pessoa));
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
public record class SampleRequest(int Count = 1, bool AddAllResponses = false);
public record class SampleResponse(PessoaEntity? pessoas);
#pragma warning restore SYSLIB1037

public partial class SampleUseCase
{
    public async Task<PessoaEntity?> ExecuteAsync()
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionString");
        var opts = new DbContextOptionsBuilder<SampleContext>().UseNpgsql(connectionString).Options;
        using var context = new SampleContext(opts);
        var pessoas = await context.Pessoas.AsNoTracking().ToArrayAsync();
        foreach (var pessoa in pessoas)
            Console.WriteLine($"{pessoa.Id}, {pessoa.Nome}, {pessoa.DataNascimento:dd/MM/yyyy}");
        return pessoas.FirstOrDefault();
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