using System.Text.Json;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;
using static System.Console;
using static AwsPlayground.Extensions;

namespace AwsPlayground;

/// <summary>
/// Exemplos utilizando o SDK AWS + serialização como json nativo
/// </summary>
public class BasicClientSampleWithJson
{
    private const string ClassName = nameof(BasicClientSampleWithJson);
    private readonly AmazonDynamoDBClient _client;

    public BasicClientSampleWithJson(AmazonDynamoDBClient client)
    {
        _client = client;
    }

    public async Task<TData?> GetItemAsync<TData>(Guid id, string sk)
    {
        Write($"{ClassName}.GetItemAsync(Id: {id}, SK: {sk})...");
        try
        {
            var request = new GetItemRequest
            {
                TableName = "Vendas",
                Key = new Dictionary<string, AttributeValue>
            {
                { "Id", new(id.ToString()) },
                { "SK", new(sk) },
            }
            };
            var response = await _client.GetItemAsync(request);
            // if (response.HttpStatusCode != System.Net.HttpStatusCode.OK)
            //     throw new AmazonDynamoDBException("GetItemAsync exception.");

            if (response.Item.Count == 0)
                return default;

            var itemAsDocument = Document.FromAttributeMap(response.Item);
            var item = JsonSerializer.Deserialize<TData>(itemAsDocument.ToJson());
            return item;
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
    }

    public async Task PutItemAsync(string table, object entity)
    {
        Write($"{ClassName}.PutItemAsync(table: {table}, entity: {entity.GetType().Name})...");
        var entityAsJson = JsonSerializer.Serialize(entity);
        var itemAsDocument = Document.FromJson(entityAsJson);
        var itemAsAttributes = itemAsDocument.ToAttributeMap();

        var putItemRequest = new PutItemRequest
        {
            TableName = table,
            Item = itemAsAttributes
        };
        var response = await _client.PutItemAsync(putItemRequest);
        // if (response.HttpStatusCode != System.Net.HttpStatusCode.OK)
        //     throw new AmazonDynamoDBException("PutItemAsync exception.");
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

        await PutItemAsync("Vendas", venda); // Insere ou atualiza completamente o documento com a partition key (id) informada
        await PutItemAsync("Vendas", itens); // Insere ou atualiza completamente o documento com a partition key (id) informada

        WriteLine($"Venda inserida");
        PrintLine();
    }
}

public record class Venda(
    Guid Id,
    string SK,
    long ExpireOn,
    DateTime Data,
    Cliente Cliente,
    decimal ValorTotal,
    Pagamento Pagamento)
{
    public Guid? ClienteId => Cliente?.Id;
}

public record class Cliente(Guid Id, string Nome);

public record class Pagamento(string Metodo, decimal Valor);

public record class VendaItem(
    Guid Id,
    string Nome,
    decimal ValorUnitario,
    decimal Quantidade,
    decimal ValorTotal);

public record class VendaItemRoot(
    Guid Id,
    string SK,
    long ExpireOn,
    Guid ClienteId,
    VendaItem[] Itens);