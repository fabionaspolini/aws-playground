using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DocumentModel;
using static System.Console;
using static AwsPlayground.Extensions;

namespace AwsPlayground;

/// <summary>
/// Exemplos utilizando "Amazon.DynamoDBv2.DocumentModel" como camada de acesso ao dado
/// </summary>
public class DocumentModelSample
{
    private readonly AmazonDynamoDBClient _client;

    public DocumentModelSample(AmazonDynamoDBClient client)
    {
        _client = client;
    }

    public async Task GetItemWithDocumentModelAsync(Guid id, string sk)
    {
        WriteLine($"GetItemWithDocumentModelAsync(Id: {id}, SK: {sk})");
        var table = Table.LoadTable(_client, "Vendas");
        var item = await table.GetItemAsync(id.ToString(), sk);
        WriteLine(item.Humanize());
        PrintLine();
    }

    public async Task QueryWithDocumentModelAsync(string sk, Guid? id = null, Guid? clienteId = null)
    {
        WriteLine($"QueryWithDocumentModelAsync(Id: {id}, ClienteId: {clienteId}, SK: {sk})");
        var table = Table.LoadTable(_client, "Vendas");
        var queryConfig = new QueryOperationConfig
        {
            KeyExpression = new Expression()
        };
        if (id.HasValue)
        {
            queryConfig.KeyExpression.ExpressionStatement = "Id = :id and SK = :sk";
            queryConfig.KeyExpression.ExpressionAttributeValues[":id"] = id;
        }
        else
        {
            queryConfig.IndexName = "VendasPorClienteIndex";
            queryConfig.KeyExpression.ExpressionStatement = "ClienteId = :clienteId and SK = :sk";
            queryConfig.KeyExpression.ExpressionAttributeValues[":clienteId"] = clienteId;
        }
        queryConfig.KeyExpression.ExpressionAttributeValues[":sk"] = sk;

        var response = table.Query(queryConfig);
        do
        {
            var items = await response.GetNextSetAsync();
            WriteLine($"Items: {items.Count}");
            items.ForEach(x => WriteLine(x.Humanize()));
        } while (!response.IsDone);

        PrintLine();
    }

    public async Task PutItemWithDocumentModelAsync(Guid vendaId, Guid clienteId)
    {
        WriteLine("PutItemWithDocumentModelAsync");

        var venda = new Document
        {
            ["Id"] = vendaId,
            ["SK"] = "cabeçalho",
            ["ExpireOn"] = DateTime.UtcNow.AddDays(2).ToUnixTime(),
            ["Data"] = DateTime.Now,
            ["ClienteId"] = clienteId,
            ["Cliente"] = new Document
            {
                ["Id"] = clienteId,
                ["Nome"] = "Fulano with DocumentModel",
            },
            ["ValorTotal"] = 488.8,
            ["Pagamento"] = new Document
            {
                ["Metodo"] = "Cartão",
                ["Valor"] = 488.8,
            }
        };

        var table = Table.LoadTable(_client, "Vendas");
        _ = await table.PutItemAsync(venda);

        WriteLine($"Venda inserida com document model");
        PrintLine();
    }
}
