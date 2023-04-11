using Amazon;
using Amazon.DynamoDBv2;
using AwsPlayground;
using static System.Console;

var clientConfig = new AmazonDynamoDBConfig
{
    RegionEndpoint = RegionEndpoint.USEast1,
    // ServiceURL = "http://localhost:4566", // localstack
};

// var vendaId = Guid.NewGuid();
// var documentModelVendaId = Guid.NewGuid();
// var dataCadastro = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss.fffff");
// var clienteId = Guid.NewGuid();
// var clienteId = Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b");
// WriteLine($"Id: {vendaId}, DataCadastro: {dataCadastro}");

var client = new AmazonDynamoDBClient(clientConfig);
var basicClientSample = new BasicClientSample(client);
var basicClientSampleWithJson = new BasicClientSampleWithJson(client);
var documentModelSample = new DocumentModelSample(client);


// Exemplos utilizando o SDK AWS sem nenhuma abstração
var basicVendaId = Guid.Parse("452877c2-3338-41a6-9a70-e0092eae42b8");
var basicClienteId = Guid.Parse("4e4c9d00-e941-493c-93ed-54f5530de360");
await basicClientSample.ListarTabelasSync();
await basicClientSample.PutItemAsync(basicVendaId, basicClienteId);
await basicClientSample.GetItemAsync(basicVendaId, "cabeçalho");
await basicClientSample.GetItemAsync(basicVendaId, "itens");
await basicClientSample.GetItemAsync(Guid.NewGuid(), "cabeçalho"); // Teste para não encontrar registro
await basicClientSample.UpdateItemAsync(basicVendaId);
await basicClientSample.QueryAsync(id: basicVendaId, sk: "itens");
await basicClientSample.QueryAsync(clienteId: basicClienteId, sk: "cabeçalho");
await basicClientSample.QueryAsync(clienteId: basicClienteId, sk: "itens");
await basicClientSample.ScanAsync();
await basicClientSample.ScanAsync(valorTotalMaiorIgual: 400);
await basicClientSample.ScanAsync(valorTotalMenorIgual: 400);
await basicClientSample.ScanAsync(nomeClienteContém: "trano");
// await basicClientSample.ScanAsync(nomeClienteContém: "trano", valorTotalMenorIgual: 400); // Não é permitido usar FitlerExpression e ScanFilter na mesma operação
await basicClientSample.ScanAsync(nomeClienteContém: "lano");

// await documentModelSample.GetItemWithDocumentModelAsync(Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), "cabeçalho");
// await documentModelSample.PutItemWithDocumentModelAsync(documentModelVendaId, clienteId);
// await documentModelSample.QueryWithDocumentModelAsync(clienteId: Guid.Parse("3e3ab209-48c4-47cd-a1c9-de34e4a04b8b"), sk: "cabeçalho");
// await documentModelSample.QueryWithDocumentModelAsync(id: Guid.Parse("ec8b14d5-b372-47ae-a164-87071cd46e87"), sk: "cabeçalho");

// Exemplos utilizando o SDK AWS + serialização como json nativo
// var jsonVendaId = Guid.Parse("09c66518-403d-440d-a488-8d27aedc747d");
// var jsonClienteId = Guid.Parse("3c9125b2-3f91-4f05-978b-d25ccc4eac3f");
// await basicClientSampleWithJson.PutItemAndPrintAsync(jsonVendaId, jsonClienteId);
// await basicClientSampleWithJson.GetItemAndPrintAsync(jsonVendaId);

WriteLine("Fim");
