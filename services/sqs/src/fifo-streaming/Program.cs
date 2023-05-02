using Amazon.SQS;
using Amazon.SQS.Model;
using static System.Console;

const int MaxMessages = 10;
const int WaitTimeSeconds = 20; // Tempo de long pooling. Se a mensagem entrar neste periodo é encaminhada instaneamente ao consumidor. Sobreescre configuração padrão da fila.
int FetchCount = 0;

var applicationCancel = new CancellationTokenSource();
CancelKeyPress += (_, e) =>
{
    WriteLine("Encerrando aplicação...");
    e.Cancel = true;
    applicationCancel.Cancel();
    WriteLine("bye...");
};

WriteLine(".:: SQS - FIFO Streaming Workflow Playground ::.");

const string QueueName = "my-streaming.fifo";

var sqsClient = new AmazonSQSClient();
var queueResponse = await sqsClient.GetQueueUrlAsync(QueueName);

var sendMessagesTasks = new Task[]
{
    SendMessagesAsync(sqsClient, queueResponse.QueueUrl, "01", 6),
    SendMessagesAsync(sqsClient, queueResponse.QueueUrl, "02", 6),
    SendMessagesAsync(sqsClient, queueResponse.QueueUrl, "03", 6),
};

// Num exemplo com 3 grupos de mensagem sendo produzidas e 4 consumidores, um dos consumidores estará sempre ocioso
var workers = new Task[]
{
    StartConsumerWorkerTask(sqsClient, queueResponse.QueueUrl, "Thread 01", applicationCancel.Token),
    StartConsumerWorkerTask(sqsClient, queueResponse.QueueUrl, "Thread 02", applicationCancel.Token),
    StartConsumerWorkerTask(sqsClient, queueResponse.QueueUrl, "Thread 03", applicationCancel.Token),
    //StartConsumerWorkerTask(sqsClient, queueResponse.QueueUrl, "Thread 04", applicationCancel.Token),
};

Task.WaitAll(sendMessagesTasks);
Task.WaitAll(workers);


WriteLine("Fim");

Task StartConsumerWorkerTask(IAmazonSQS sqsClient, string queueUrl, string consumerIdentifier, CancellationToken cancellationToken)
{
    return Task.Run(async () =>
    {
        while (!cancellationToken.IsCancellationRequested)
        {
            var fetchIndex = ++FetchCount;
            var messages = await GetMessages(sqsClient, queueResponse.QueueUrl, WaitTimeSeconds, cancellationToken);
            var hasErrors = false;
            foreach (var message in messages.Messages)
            {
                if (hasErrors)
                    break;
                try
                {
                    LogMessage(message, QueueName, consumerIdentifier, fetchIndex);
                    //await Task.Delay(2000);

                    //var group = message.Attributes.FirstOrDefault(x => x.Key == "MessageGroupId");
                    //if (group.Value == "01" && message.Body == "Teste 3")
                    //    throw new Exception("Simulação de erro");

                    await sqsClient.DeleteMessageAsync(queueResponse.QueueUrl, message.ReceiptHandle); // Remover mensagem da fila. Sinal de processada com sucesso.
                }
                catch (Exception ex)
                {
                    // Cuidado com o conceito de streaming de dados. Se decidir por ignorar a mensagem de erro e seguir para próxima, você poderá
                    // ignorar um mensagem que é pre-requisito para o grupo de processamento e desencadear um erro em cascata para todo o group id.
                    // DLQ's para streaming podem não se encaixar adequadamente.
                    Error.WriteLine($"Erro ao processar mensagem: {ex}");
                    hasErrors = true;
                }
            }
            //await Task.Delay(3000);
        }
    }, CancellationToken.None);
}

static void LogMessage(Message message, string queueName, string consumerIdentifier, int fetchIndex)
{
    var group = message.Attributes.FirstOrDefault(x => x.Key == "MessageGroupId");

    WriteLine($"{DateTime.Now:dd/MM/yyyy HH:mm:ss.fff} {queueName} [{consumerIdentifier} - Fetch: {fetchIndex}] => Group: {group.Value}. Message: {message.Body}");
}

static async Task<ReceiveMessageResponse> GetMessages(IAmazonSQS sqsClient, string qUrl, int waitTime, CancellationToken cancellationToken)
{
    return await sqsClient.ReceiveMessageAsync(new ReceiveMessageRequest
    {
        QueueUrl = qUrl,
        MaxNumberOfMessages = MaxMessages,
        WaitTimeSeconds = waitTime,
        AttributeNames = new List<string>() { "All" },
        MessageAttributeNames = new List<string>() { "All" },
    }, cancellationToken);
}

static async Task SendMessagesAsync(IAmazonSQS sqsClient, string queueUrl, string messageGroupId, int qtd)
{
    for (var i = 0; i < qtd; i++)
    {
        var message = new SendMessageRequest
        {
            QueueUrl = queueUrl,
            MessageGroupId = messageGroupId,
            MessageDeduplicationId = Guid.NewGuid().ToString(), // Cuidado! Isso é apenas para testes. Provavelmente no seu caso de uso há um código de negócio para utilizar aqui.
            MessageBody = $"Teste {i + 1}",
        };
        await sqsClient.SendMessageAsync(message);
    }
}