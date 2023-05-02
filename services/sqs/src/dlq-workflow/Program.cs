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

Task StartConsumerWorkerTask(IAmazonSQS sqsClient, string queueName, int maxReceiveCount, CancellationToken cancellationToken)
{
    return Task.Run(async () =>
    {
        var queueResponse = await sqsClient.GetQueueUrlAsync(queueName);
        while (!cancellationToken.IsCancellationRequested)
        {
            var messages = await GetMessage(sqsClient, queueResponse.QueueUrl, WaitTimeSeconds);
            foreach (var message in messages.Messages)
            {
                LogMessage(message, queueName, maxReceiveCount);
                // await sqsClient.DeleteMessageAsync(queueResponse.QueueUrl, message.ReceiptHandle); // Remover mensagem da fila. Sinal de processada com sucesso.
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
        WriteLine(string.Join("\n", message.MessageAttributes.Select(x => $"    {x.Key}: {x.Value.StringValue}")));
    }

    var receiveCountStr = message.Attributes["ApproximateReceiveCount"];
    if (!string.IsNullOrWhiteSpace(receiveCountStr))
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


static async Task<ReceiveMessageResponse> GetMessage(IAmazonSQS sqsClient, string qUrl, int waitTime = 0)
{
    return await sqsClient.ReceiveMessageAsync(new ReceiveMessageRequest
    {
        QueueUrl = qUrl,
        MaxNumberOfMessages = MaxMessages,
        WaitTimeSeconds = waitTime,
        AttributeNames = new List<string>() { "All" },
        MessageAttributeNames = new List<string>() { "All" },
    });
}

static async Task DeleteMessage(IAmazonSQS sqsClient, Message message, string qUrl)
{
    WriteLine($"\nDeleting message {message.MessageId} from queue...");
    await sqsClient.DeleteMessageAsync(qUrl, message.ReceiptHandle);
}