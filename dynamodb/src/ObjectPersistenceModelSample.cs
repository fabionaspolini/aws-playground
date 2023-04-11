using Amazon.DynamoDBv2.DataModel;
using Amazon.DynamoDBv2.DocumentModel;
using ServiceStack;
using ServiceStack.Aws.DynamoDb;
using static System.Console;
using static AwsPlayground.Extensions;

namespace AwsPlayground;

/// <summary>
/// Exemplos utilizando abstração do SDK AWS: .NET Object Persistence Model <see href="https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DotNetSDKHighLevel.html"/>.
/// </summary>
public class ObjectPersistenceModelSample
{
    private const string ClassName = nameof(ObjectPersistenceModelSample);
    private readonly DynamoDBContext _context;

    public ObjectPersistenceModelSample(DynamoDBContext context) => _context = context;

    public async Task PutItemAsync<TEntity>(TEntity entity)
    {
        Write($"{ClassName}.PutItemAsync(entity: {entity.GetType().Name})...");
        //var response = await _context.PutItemAsync(entity);
        await _context.SaveAsync(entity);
        WriteLine("OK.");
    }

    public async Task PutItemAndPrintAsync(Guid vendaId, Guid clienteId)
    {
        WriteLine($"{ClassName}.PutItemAndPrintAsync(vendaId: {vendaId}, clienteId: {clienteId})");
        var venda = new Venda(
            Id: vendaId,
            SK: "cabeçalho",
            ExpireOn: DateTime.UtcNow.AddDays(2).ToUnixTime(),
            Data: DateTime.UtcNow,
            Cliente: new(
                Id: clienteId,
                Nome: "Fulano from C# JSON"),
            ValorTotal: 488.8m,
            Pagamento: new(
                Metodo: "Cartão",
                Valor: 488.8m));
        var itens = new VendaItemRoot(
            Id: vendaId,
            SK: "itens",
            ExpireOn: DateTime.UtcNow.AddDays(2).ToUnixTime(),
            ClienteId: clienteId,
            Itens: new VendaItem[]
            {
                new(
                    Id: Guid.NewGuid(),
                    Nome: "Batedeira",
                    ValorUnitario: 199.9m,
                    Quantidade: 2,
                    ValorTotal: 399.8m),
                new(
                    Id: Guid.NewGuid(),
                    Nome: "Liquidificador",
                    ValorUnitario: 89.0m,
                    Quantidade: 1,
                    ValorTotal: 89.0m),
            }
        );

        await PutItemAsync(venda); // Insere ou atualiza completamente o documento com a partition key (id) informada
        await PutItemAsync(itens); // Insere ou atualiza completamente o documento com a partition key (id) informada

        WriteLine($"Venda inserida");
        PrintLine();
    }

    public async Task<TData?> GetItemAsync<TData>(Guid id, string sk)
    {
        Write($"{ClassName}.GetItemAsync(Id: {id}, SK: {sk})...");
        try
        {
            var result = await _context.LoadAsync<TData>(id, sk);
            return result;
        }
        finally
        {
            WriteLine("OK.");
        }
    }

    public async Task GetItemAndPrintAsync(Guid id)
    {
        var venda = (await GetItemAsync<Venda>(id, "cabeçalho"))!;
        var itens = (await GetItemAsync<VendaItemRoot>(id, "itens"))!;

        WriteLine($"{ClassName}.GetItemAndPrintAsync(id: {id})");
        WriteLine($"ClienteId: {venda.ClienteId}, Cliente.Nome: {venda.Cliente.Nome}, ValorTotal: {venda.ValorTotal}, Itens: {itens.Itens.Length}");
        PrintLine();
    }

    /// <summary>
    /// Operação lenta por não ser direcionada a uma partition key definida
    /// </summary>
    /// <param name="valorTotalMaiorIgual"></param>
    /// <param name="valorTotalMenorIgual"></param>
    /// <returns></returns>
    public async Task ScanAsync(
        decimal? valorTotalMaiorIgual = null,
        decimal? valorTotalMenorIgual = null,
        string? nomeClienteContém = null)
    {
        WriteLine($"{ClassName}.ScanAsync(valorTotalMaiorIgual: {valorTotalMaiorIgual}, valorTotalMenorIgual: {valorTotalMenorIgual}, nomeClienteContém: {nomeClienteContém})");

        var conditions = new List<ScanCondition>();
        conditions.Add(new("SK", ScanOperator.Equal, "cabeçalho"));

        if (valorTotalMaiorIgual.HasValue)
            conditions.Add(new("ValorTotal", ScanOperator.GreaterThanOrEqual, valorTotalMaiorIgual));
        if (valorTotalMenorIgual.HasValue)
            conditions.Add(new("ValorTotal", ScanOperator.LessThanOrEqual, valorTotalMenorIgual));
        //if (!string.IsNullOrWhiteSpace(nomeClienteContém))
        //    conditions.Add(new("Cliente.Cliente", ScanOperator.Contains, nomeClienteContém)); // Não localiza campo aninhado para filtrar :(

        //var config = new ScanOperationConfig();
        //config.FilterExpression.ExpressionStatement
        //var response = await _context.FromScanAsync<Venda>(config).GetRemainingAsync();
        var response = await _context.ScanAsync<Venda>(conditions).GetRemainingAsync();

        //var response = await query.ExecAsync();
        foreach (var venda in response)
            WriteLine($"Id: {venda.Id}, SK: {venda.SK}, ClienteId: {venda.ClienteId}, Cliente.Nome: {venda.Cliente?.Nome}, ValorTotal: {venda.ValorTotal}");

        PrintLine();
    }
}