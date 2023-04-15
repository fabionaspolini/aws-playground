using ServiceStack.Aws.DynamoDb;
using static System.Console;
using static AwsPlayground.Extensions;

namespace AwsPlayground;

/// <summary>
/// Exemplos utilizando abstração PocoDynamo <see href="https://github.com/ServiceStack/PocoDynamo"/>.
/// <para>Porém, essa lib não é gratuita para uso empresarial</para>
/// </summary>
public class PocoDynamoSample
{
    private const string ClassName = nameof(PocoDynamoSample);
    private readonly PocoDynamo _db;

    public PocoDynamoSample(PocoDynamo db) => _db = db;

    public async Task PutItemAsync<TEntity>(TEntity entity)
    {
        Write($"{ClassName}.PutItemAsync(entity: {entity.GetType().Name})...");
        var response = await _db.PutItemAsync(entity);
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
            var result = await _db.GetItemAsync<TData>(id, sk);
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

        // PocoDynamo também suporta scan nativo repassando o objeto "ScanRequest" conforme exemplo em "BasicClientSample".

        var query = _db.FromScan<Venda>();
        //query.Filter(x => x.SK == "cabeçalho");

        //if (valorTotalMaiorIgual.HasValue)
        //  query.Filter(x => x.ValorTotal >= valorTotalMaiorIgual.Value); // Concatenar filtros dessa forma gera a clausúla errado a expressão :( => FilterExpression = "(SK = :p0) AND (ValorTotal >= :p0)"

        //if (valorTotalMenorIgual.HasValue)
        //    query.Filter(x => x.ValorTotal <= valorTotalMenorIgual.Value);

        query.Filter("SK = :sk", new { sk = "cabeçalho" });
        if (valorTotalMaiorIgual.HasValue)
            query.Filter("ValorTotal >= :valorTotalMaiorIgual", new { valorTotalMaiorIgual });
        if (valorTotalMenorIgual.HasValue)
            query.Filter("ValorTotal <= :valorTotalMenorIgual", new { valorTotalMenorIgual });
        if (!string.IsNullOrWhiteSpace(nomeClienteContém))
            query.Filter("contains(Cliente.Nome, :nomeClienteContem)", new { nomeClienteContem = nomeClienteContém }); // case sensitive


        //var response = await query.ExecAsync();
        //foreach (var venda in response)
        //    WriteLine($"Id: {venda.Id}, SK: {venda.SK}, ClienteId: {venda.ClienteId}, Cliente.Nome: {venda.Cliente?.Nome}, ValorTotal: {venda.ValorTotal}");

        // Percorrer todo o scan paginando e recebendo o stream de dados
        await foreach (var venda in _db.ScanAsync<Venda>(query))
            WriteLine($"Id: {venda.Id}, SK: {venda.SK}, ClienteId: {venda.ClienteId}, Cliente.Nome: {venda.Cliente?.Nome}, ValorTotal: {venda.ValorTotal}");

        PrintLine();
    }
}