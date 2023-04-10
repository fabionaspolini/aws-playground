using Amazon;
using Amazon.DynamoDBv2;
using AwsPlayground;
using static System.Console;

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
var basicClientSample = new BasicClientSample(client);
var basicClientSampleWithJson = new BasicClientSampleWithJson(client);
var documentModelSample = new DocumentModelSample(client);


// await basicClientSample.ListarTabelasSync();
// await basicClientSample.GetItemAsync(Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), "cabeçalho");
// await basicClientSample.PutItemAsync(vendaId, clienteId);
// await basicClientSample.UpdateItemAsync(vendaId);
// await basicClientSample.QueryAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "cabeçalho");
// await basicClientSample.QueryAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "itens");
// await basicClientSample.QueryAsync(id: Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), sk: "itens");

// await documentModelSample.GetItemWithDocumentModelAsync(Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), "cabeçalho");
// await documentModelSample.PutItemWithDocumentModelAsync(documentModelVendaId, clienteId);
// await documentModelSample.QueryWithDocumentModelAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "cabeçalho");
// await documentModelSample.QueryWithDocumentModelAsync(id: Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), sk: "cabeçalho");

var jsonVendaId = Guid.Parse("09c66518-403d-440d-a488-8d27aedc747d");
var jsonClienteId = Guid.Parse("3c9125b2-3f91-4f05-978b-d25ccc4eac3f");
await basicClientSampleWithJson.PutItemAndPrintAsync(jsonVendaId, jsonClienteId);
await basicClientSampleWithJson.GetItemAndPrintAsync(jsonVendaId);

WriteLine("Fim");
