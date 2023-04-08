using Amazon;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;
using AwsPlayground;
using static System.Console;

// ******************************************************************************
// ** Exemplos utilizando o SDK AWS se nenhum abstração
// ******************************************************************************

var clientConfig = new AmazonDynamoDBConfig
{
    RegionEndpoint = RegionEndpoint.USEast1,
    // ServiceURL = "http://localhost:4566", // localstack
};

var vendaId = Guid.NewGuid();
var documentModelVendaId = Guid.NewGuid();
var dataCadastro = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fffff");
// var clienteId = Guid.NewGuid();
var clienteId = Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b");
WriteLine($"Id: {vendaId}, DataCadastro: {dataCadastro}");

var client = new AmazonDynamoDBClient(clientConfig);

await ListarTabelasSync();
await GetItemAsync(Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), "header");
await PutItemAsync();
await UpdateItemAsync();
await QueryAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "header");
await QueryAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "items");
await QueryAsync(id: Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), sk: "items");

await GetItemWithDocumentModelAsync(Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), "header");
await PutItemWithDocumentModelAsync();
await QueryWithDocumentModelAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "header");
await QueryWithDocumentModelAsync(id: Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), sk: "header");

WriteLine("Fim");

async Task ListarTabelasSync()
{
    var tables = await client.ListTablesAsync();
    WriteLine("Tabelas");
    WriteLine("-------");
    tables.TableNames.ForEach(WriteLine);
}

// ------------ Basic DynamoDB client ------------

async Task GetItemAsync(Guid id, string sk)
{
    WriteLine($"GetItemAsync(Id: {id}, SK: {sk})");
    var request = new GetItemRequest
    {
        TableName = "Vendas",
        Key = new Dictionary<string, AttributeValue>
        {
            { "Id", new(id.ToString()) },
            { "SK", new(sk) },
        }
    };
    var response = await client.GetItemAsync(request);
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

async Task QueryAsync(string sk, Guid? id = null, Guid? clienteId = null)
{
    WriteLine($"ConsultarItemAsync(Id: {id}, ClienteId: {clienteId}, SK: {sk})");
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

    var response = await client.QueryAsync(request);
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

async Task PutItemAsync()
{
    WriteLine("PutItemAsync");
    var requestHeader = new PutItemRequest
    {
        TableName = "Vendas",
        Item = new Dictionary<string, AttributeValue>
        {
            { "Id", new(vendaId.ToString()) },
            { "SK", new("header") },
            { "ExpireOn", new(DateTime.UtcNow.AddDays(2).ToUnixTime()) },
            { "Data", new(dataCadastro) },
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
            { "SK", new("items") },
            { "ExpireOn", new(DateTime.UtcNow.AddDays(2).ToUnixTime()) },
            { "Data", new(dataCadastro) },
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

    var responseHeader = await client.PutItemAsync(requestHeader); // Insere ou atualiza completamente o documento com a partition key (id) informada
    var responseItems = await client.PutItemAsync(requestItems); // Insere ou atualiza completamente o documento com a partition key (id) informada

    WriteLine($"Venda inserida");
    PrintLine();
}

async Task UpdateItemAsync()
{
    WriteLine("UpdateItemAsync");

    var request = new UpdateItemRequest
    {
        TableName = "Vendas",
        Key = new() {
            { "Id", new(vendaId.ToString()) },
            { "SK", new("header") } },
        ExpressionAttributeValues = new Dictionary<string, AttributeValue>
        {
            { ":nome", new AttributeValue{ S = "Beltrano from C#" } },
        },
        UpdateExpression = "SET Cliente.Nome = :nome"
    };
    var response = await client.UpdateItemAsync(request);

    WriteLine($"Item atualizado");
    PrintLine();
}

// ------------ Document Model ------------

async Task GetItemWithDocumentModelAsync(Guid id, string sk)
{
    WriteLine($"GetItemWithDocumentModelAsync(Id: {id}, SK: {sk})");
    var table = Table.LoadTable(client, "Vendas");
    var item = await table.GetItemAsync(id.ToString(), sk);
    WriteLine(item.Humanize());
    PrintLine();
}

async Task QueryWithDocumentModelAsync(string sk, Guid? id = null, Guid? clienteId = null)
{
    WriteLine($"QueryWithDocumentModelAsync(Id: {id}, ClienteId: {clienteId}, SK: {sk})");
    var table = Table.LoadTable(client, "Vendas");
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

async Task PutItemWithDocumentModelAsync()
{
    WriteLine("PutItemWithDocumentModelAsync");

    var venda = new Document
    {
        ["Id"] = documentModelVendaId,
        ["SK"] = "header",
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

    var table = Table.LoadTable(client, "Vendas");
    var response = await table.PutItemAsync(venda);

    WriteLine($"Venda inserida com document model");
    PrintLine();
}

void PrintLine() => WriteLine(new string('-', 80));
