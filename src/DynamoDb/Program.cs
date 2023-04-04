using Amazon;
using Amazon.DynamoDBv2;
using Amazon.DynamoDBv2.DocumentModel;
using Amazon.DynamoDBv2.Model;
using static System.Console;

var clientConfig = new AmazonDynamoDBConfig { RegionEndpoint = RegionEndpoint.USEast1, ServiceURL = "http://localhost:8000" };

var client = new AmazonDynamoDBClient(clientConfig);
var tables = await client.ListTablesAsync();

WriteLine("Tabelas");
tables.TableNames.ForEach(WriteLine);
WriteLine(new string('-', 80));

var id = Guid.NewGuid();
var anoMes = DateTime.Now.ToString("yyyy-MM");
var dataCadastro = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fffff");
WriteLine($"Id: {id}, DataCadastro: {dataCadastro}");

// Inserir
var insertRequest = new PutItemRequest
{
    TableName = "Venda",
    Item = new Dictionary<string, AttributeValue>
    {
        { "Id", new() { S = id.ToString() } },
        { "AnoMes", new() { S = anoMes } },
        { "DataCadastro", new() { S = dataCadastro } },
        { "Cliente", new() { M = new()
            {
                { "Id", new() { S = Guid.NewGuid().ToString() } },
                { "Nome", new() { S = "Fulano" } },
            } } },
        { "Itens", new() { L = new()
            {
                new() { M = new ()
                {
                    {"Id", new() { S = Guid.NewGuid().ToString()} },
                    {"Nome", new() { S = "Batedeira"} },
                    {"ValorUnitario", new() { N = "199.90"} },
                    {"Quantidade", new() { N = "2"} },
                    {"ValorTotal", new() { N = "399.8"} },
                } },
                new() { M = new ()
                {
                    {"Id", new() { S = Guid.NewGuid().ToString()} },
                    {"Nome", new() { S = "Liquidificador"} },
                    {"ValorUnitario", new() { N = "89.00"} },
                    {"Quantidade", new() { N = "1"} },
                    {"ValorTotal", new() { N = "89.00"} },
                } },
            } } }
    }
};
var insertResponse = await client.PutItemAsync(insertRequest); // Insere ou atualiza completamente o documento com a partition key (id) informada
WriteLine($"Insert response: {insertResponse.HttpStatusCode}");

// Atualização parcial do objeto
var updatePartialRequest = new UpdateItemRequest
{
    TableName = "Venda",
    Key = new() {
        { "Id", new() { S = id.ToString() } },
        { "AnoMes", new() { S = anoMes } } },
    ExpressionAttributeValues = new Dictionary<string, AttributeValue>
    {
        { ":nome", new AttributeValue{ S = "Beltrano" } },
    },
    UpdateExpression = "SET Cliente.Nome = :nome"
};
var updatePartialResponse = await client.UpdateItemAsync(updatePartialRequest);
WriteLine($"Update partial response: {updatePartialResponse.HttpStatusCode}");
WriteLine(new string('-', 80));

// Consultar documento
var getItemResponse = await client.GetItemAsync("Venda", new()
{
    { "AnoMes", new() { S = anoMes.ToString() }},
    { "Id", new() { S = id.ToString() }},
});
WriteLine($"GetItem response\r\n{string.Join("\r\n", getItemResponse.Item.Select(x => $"{x.Key} = {x.Value.S ?? x.Value.N}"))}");
WriteLine(new string('-', 80));

// Consultar documento no formato json
var vendaTable = Table.LoadTable(client, "Venda");
var item = await vendaTable.GetItemAsync(anoMes, id.ToString());
WriteLine($"Get item response [Table access]\r\n{item.ToJsonPretty()}");
WriteLine(new string('-', 80));

// Listar registros
var scanFilters = new ScanFilter();
// scanFilters.AddCondition("AnoMes", ScanOperator.Equal, anoMes);

var scan = vendaTable.Scan(scanFilters);
WriteLine($"Scan response count: {scan.Count}");
WriteLine("Scan items");
do
{
    var scanItems = await scan.GetNextSetAsync();
    scanItems.ForEach(x => WriteLine(x.ToJson()));
} while (!scan.IsDone);
WriteLine(new string('-', 80));

WriteLine("Fim");