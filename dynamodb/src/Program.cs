using Amazon;
using Amazon.DynamoDBv2;
using AwsPlayground;
using ServiceStack.Aws.DynamoDb;
using static ServiceStack.Diagnostics.Events;
using static System.Console;

var clientConfig = new AmazonDynamoDBConfig
{
    RegionEndpoint = RegionEndpoint.USEast1,
    // ServiceURL = "http://localhost:4566", // localstack
};
var client = new AmazonDynamoDBClient(clientConfig);

// ===== Exemplos utilizando o SDK AWS sem nenhuma abstração =====
//var basicVendaId = Guid.Parse("452877c2-3338-41a6-9a70-e0092eae42b8");
//var basicClienteId = Guid.Parse("4e4c9d00-e941-493c-93ed-54f5530de360");
//var basicClientSample = new BasicClientSample(client);
//await basicClientSample.ListarTabelasSync();
//await basicClientSample.PutItemAsync(basicVendaId, basicClienteId);
//await basicClientSample.GetItemAsync(basicVendaId, "cabeçalho");
//await basicClientSample.GetItemAsync(basicVendaId, "itens");
//await basicClientSample.GetItemAsync(Guid.NewGuid(), "cabeçalho"); // Teste para não encontrar registro
//await basicClientSample.UpdateItemAsync(basicVendaId);
//await basicClientSample.QueryAsync(id: basicVendaId, sk: "itens");
//await basicClientSample.QueryAsync(clienteId: basicClienteId, sk: "cabeçalho");
//await basicClientSample.QueryAsync(clienteId: basicClienteId, sk: "itens");
//await basicClientSample.ScanAsync();
//await basicClientSample.ScanAsync(valorTotalMaiorIgual: 400);
//await basicClientSample.ScanAsync(valorTotalMenorIgual: 400);
//await basicClientSample.ScanAsync(nomeClienteContém: "trano");
//await basicClientSample.ScanAsync(nomeClienteContém: "lano");

// ===== Exemplos Amazon.DynamoDBv2.DocumentModel =====
//var documentModelVendaId = Guid.Parse("dffe4118-3831-4f64-bfce-bc230ffe0c40");
//var documentModelClienteId = Guid.Parse("7b195d4e-3580-49e7-9db3-8567237c6a91");
//var documentModelSample = new DocumentModelSample(client);
//await documentModelSample.PutItemWithDocumentModelAsync(documentModelVendaId, documentModelClienteId);
//await documentModelSample.GetItemWithDocumentModelAsync(documentModelVendaId, "cabeçalho");
//await documentModelSample.QueryWithDocumentModelAsync(clienteId: documentModelClienteId, sk: "cabeçalho");
//await documentModelSample.QueryWithDocumentModelAsync(id: documentModelVendaId, sk: "cabeçalho");

// ===== Exemplos utilizando o SDK AWS + serialização como json nativo =====
//var jsonVendaId = Guid.Parse("09c66518-403d-440d-a488-8d27aedc747d");
//var jsonClienteId = Guid.Parse("3c9125b2-3f91-4f05-978b-d25ccc4eac3f");
//var basicClientSampleWithJson = new BasicClientSampleWithJson(client);
//await basicClientSampleWithJson.PutItemAndPrintAsync(jsonVendaId, jsonClienteId);
//await basicClientSampleWithJson.GetItemAndPrintAsync(jsonVendaId);

// ===== Exemplos utilizando abstração PocoDynamo =====
var pocoDynamoVendaId = Guid.Parse("932b69ff-5ae6-4bc2-8207-93dc137ee917");
var pocoDynamoClienteId = Guid.Parse("de5562e9-3464-48e8-bf40-377e68df9b22");
var pocoDynamoDb = new PocoDynamo(client);
pocoDynamoDb.RegisterTable<Venda>();
pocoDynamoDb.RegisterTable<VendaItemRoot>();
var pocoDynamoClientSample = new PocoDynamoSample(pocoDynamoDb);
await pocoDynamoClientSample.PutItemAndPrintAsync(pocoDynamoVendaId, pocoDynamoClienteId);
await pocoDynamoClientSample.GetItemAndPrintAsync(pocoDynamoVendaId);
await pocoDynamoClientSample.ScanAsync();
await pocoDynamoClientSample.ScanAsync(valorTotalMaiorIgual: 400);
await pocoDynamoClientSample.ScanAsync(valorTotalMenorIgual: 400);
await pocoDynamoClientSample.ScanAsync(nomeClienteContém: "lano");
await pocoDynamoClientSample.ScanAsync(nomeClienteContém: "lano", valorTotalMaiorIgual: 400);
await pocoDynamoClientSample.ScanAsync(nomeClienteContém: "aaaaa");

WriteLine("Fim");
