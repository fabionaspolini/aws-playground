using Amazon.SQS;
using Amazon.SQS.Model;
using static System.Console;

const int MaxMessages = 10;
const int WaitTimeSeconds = 20; // Tempo de long pooling. Se a mensagem entrar neste periodo é encaminhada instaneamente ao consumidor. Sobreescre configuração padrão da fila.

var applicationCancel = new CancellationTokenSource();
CancelKeyPress += (_, e) =>
{
    WriteLine("Encerrando aplicação...");
    e.Cancel = true;
    applicationCancel.Cancel();
    WriteLine("bye...");
};

WriteLine(".:: SQS - DLQ Workflow Playground ::.");

var sqsClient = new AmazonSQSClient();

var workers = new Task[]
{
    StartConsumerWorkerTask(sqsClient, "my-action", 3, applicationCancel.Token),
    StartConsumerWorkerTask(sqsClient, "my-action-dlq-retry", 6, applicationCancel.Token)
};

Task.WaitAll(workers);


WriteLine("Fim");

/// <summary>
/// Iniciar uma thread para processamente de mensagens da fila
/// </summary>
/// <param name="sqsClient"></param>
/// <param name="queueName"></param>
/// <param name="maxReceiveCount">Apenas para mensagem de log de redirecionamento a outra fila</param>
/// <param name="cancellationToken"></param>
/// <returns></returns>
Task StartConsumerWorkerTask(IAmazonSQS sqsClient, string queueName, int maxReceiveCount, CancellationToken cancellationToken)
{
    return Task.Run(async () =>
    {
        var queueResponse = await sqsClient.GetQueueUrlAsync(queueName);
        while (!cancellationToken.IsCancellationRequested)
        {
            var messages = await GetMessages(sqsClient, queueResponse.QueueUrl, WaitTimeSeconds, cancellationToken);
            foreach (var message in messages.Messages)
            {
                try
                {
                    LogMessage(message, queueName, maxReceiveCount);
                    // await sqsClient.DeleteMessageAsync(queueResponse.QueueUrl, message.ReceiptHandle); // Remover mensagem da fila. Sinal de processada com sucesso.
                }
                catch (Exception e)
                {
                    // Como é um mensageria e não um streaming de dados, não há problema tratar o erro e seguir para próxima mensagem.
                    // Como não executou o "DeleteMessageAsync" na situação de erro, a mensagem ficará invísvel até que expire o "Visibility Timeout" da fila.
                    // Então será entregue novamente ao consumidor até que processe com sucesso ou ultrapasse o limite de entregas para redirecionar para DLQ
                    Error.WriteLine("Erro ao processar mensagem: " + e);
                }
            }
        }
    }, CancellationToken.None);
}

static void LogMessage(Message message, string queueName, int maxReceiveCount)
{
    WriteLine($"{DateTime.Now:dd/MM/yyyy HH:mm:ss.fff} {queueName} => Id: {message.MessageId} - {message.Body}");
    WriteLine("message.Attributes");
    WriteLine(string.Join("\n", message.Attributes.Select(x => $"    {x.Key}: {x.Value}")));

    if (message.MessageAttributes.Any())
    {
        WriteLine();
        WriteLine("message.MessageAttributes");
        WriteLine(string.Join("\n", message.MessageAttributes.Select(x => $"    {x.Key}: {x.Value.StringValue}"))); // Metadados implícitos da AWS
    }

    var receiveCountStr = message.Attributes["ApproximateReceiveCount"];
    if (!string.IsNullOrWhiteSpace(receiveCountStr)) // Atributos personalizados da mensagem
    {
        var receiveCount = int.Parse(receiveCountStr);
        if (receiveCount >= maxReceiveCount)
        {
            WriteLine();
            WriteLine("--> Mover para próxima dlq");
            WriteLine();
        }
    }

    WriteLine(new string('-', 100));
}


static async Task<ReceiveMessageResponse> GetMessages(IAmazonSQS sqsClient, string qUrl, int waitTimeSeconds, CancellationToken cancellationToken)
{
    return await sqsClient.ReceiveMessageAsync(new ReceiveMessageRequest
    {
        QueueUrl = qUrl,
        MaxNumberOfMessages = MaxMessages,
        WaitTimeSeconds = waitTimeSeconds,
        AttributeNames = new List<string>() { "All" },
        MessageAttributeNames = new List<string>() { "All" }
    }, cancellationToken);
}
