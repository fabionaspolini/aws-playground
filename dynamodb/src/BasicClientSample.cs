using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.Model;
using static System.Console;
using static AwsPlayground.Extensions;

namespace AwsPlayground;

/// <summary>
// Exemplos utilizando o SDK AWS se nenhuma abstração
/// </summary>
public class BasicClientSample
{
    private readonly AmazonDynamoDBClient _client;

    public BasicClientSample(AmazonDynamoDBClient client)
    {
        _client = client;
    }

    public async Task ListarTabelasSync()
    {
        var tables = await _client.ListTablesAsync();
        WriteLine("Tabelas");
        WriteLine("-------");
        tables.TableNames.ForEach(WriteLine);
        PrintLine();
    }

    public async Task GetItemAsync(Guid id, string sk)
    {
        WriteLine($"BasicClientSample.GetItemAsync(Id: {id}, SK: {sk})");
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
        if (response.Item.Count == 0)
        {
            Write($"Documento Id: {id} e sk: {sk} não encontrado.");
            PrintLine();
            return;
        }

        // var itemAsDocument = Document.FromAttributeMap(response.Item);
        // var item = JsonSerializer.Deserialize<DTO>(itemAsDocument);

        WriteLine(response.Item.Humanize());
        PrintLine();
    }

    public async Task QueryAsync(string sk, Guid? id = null, Guid? clienteId = null)
    {
        WriteLine($"BasicClientSample.ConsultarItemAsync(Id: {id}, ClienteId: {clienteId}, SK: {sk})");
        var request = new QueryRequest
        {
            TableName = "Vendas",
            IndexName = id.HasValue ? null : "VendasPorClienteIndex",
            KeyConditionExpression = id.HasValue
                ? "Id = :id and SK = :sk"
                : "ClienteId = :clienteId and SK = :sk"
        };
        if (id.HasValue)
            request.ExpressionAttributeValues.Add(":id", new(id.ToString()));
        if (clienteId.HasValue)
            request.ExpressionAttributeValues.Add(":clienteId", new(clienteId.ToString()));
        request.ExpressionAttributeValues.Add(":sk", new(sk.ToString()));

        var response = await _client.QueryAsync(request);
        if (response.Items.Count == 0)
        {
            Write("Nenhum item encontrado");
            PrintLine();
            return;
        }
        WriteLine($"Items: {response.Items.Count}");

        response.Items.ForEach(x => WriteLine(x.Humanize()));

        PrintLine();
    }

    public async Task PutItemAsync(Guid vendaId, Guid clienteId)
    {
        WriteLine($"BasicClientSample.PutItemAsync(vendaId: {vendaId}, clienteId: {clienteId})");
        var requestHeader = new PutItemRequest
        {
            TableName = "Vendas",
            Item = new Dictionary<string, AttributeValue>
            {
                { "Id", new(vendaId.ToString()) },
                { "SK", new("cabeçalho") },
                { "ExpireOn", new(DateTime.UtcNow.AddDays(2).ToUnixTime().ToString()) },
                { "Data", new(GetDataFormatada()) },
                { "ClienteId", new(clienteId.ToString()) },
                { "Cliente", new() { M = new()
                    {
                        { "Id", new(clienteId.ToString()) },
                        { "Nome", new("Fulano from C#") },
                } } },
                { "ValorTotal", new() { N = "488.8" } },
                { "Pagamento", new() { M = new ()
                    {
                        {"Metodo", new("Cartão") },
                        {"Valor", new() { S = "488.8"} },
                } } }
            }
        };

        var requestItems = new PutItemRequest
        {
            TableName = "Vendas",
            Item = new Dictionary<string, AttributeValue>
            {
                { "Id", new(vendaId.ToString()) },
                { "SK", new("itens") },
                { "ExpireOn", new(DateTime.UtcNow.AddDays(2).ToUnixTime().ToString()) },
                { "Data", new(GetDataFormatada()) },
                { "ClienteId", new(clienteId.ToString()) },
                { "Itens", new() { L = new()
                    {
                        new() { M = new ()
                        {
                            {"Id", new(Guid.NewGuid().ToString()) },
                            {"Nome", new("Batedeira") },
                            {"ValorUnitario", new() { N = "199.90"} },
                            {"Quantidade", new() { N = "2"} },
                            {"ValorTotal", new() { N = "399.8"} },
                        } },
                        new() { M = new ()
                        {
                            {"Id", new(Guid.NewGuid().ToString()) },
                            {"Nome", new("Liquidificador") },
                            {"ValorUnitario", new() { N = "89.00"} },
                            {"Quantidade", new() { N = "1"} },
                            {"ValorTotal", new() { N = "89.00"} },
                        } },
                    } } }
            }
        };

        _ = await _client.PutItemAsync(requestHeader); // Insere ou atualiza completamente o documento com a partition key (id) informada
        _ = await _client.PutItemAsync(requestItems); // Insere ou atualiza completamente o documento com a partition key (id) informada

        WriteLine($"Venda inserida");
        PrintLine();
    }

    public async Task UpdateItemAsync(Guid vendaId)
    {
        WriteLine($"BasicClientSample.UpdateItemAsync (vendaId: {vendaId})");

        var request = new UpdateItemRequest
        {
            TableName = "Vendas",
            Key = new()
            {
                { "Id", new(vendaId.ToString()) },
                { "SK", new("cabeçalho") }
            },
            ExpressionAttributeValues = new Dictionary<string, AttributeValue>
            {
                { ":nome", new AttributeValue{ S = "Beltrano from C#" } },
            },
            UpdateExpression = "SET Cliente.Nome = :nome"
        };
        _ = await _client.UpdateItemAsync(request);

        WriteLine($"Item atualizado");
        PrintLine();
    }

    private static string GetDataFormatada() => DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fffff");
}
