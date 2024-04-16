# Lambda

- [Visão geral](#visão-geral)
- [Network](#network)
  - [Terraform](#terraform)
- [Invocações sincronas](#invocações-sincronas)
  - [HTTP](#http)
- [Invocações assíncronas](#invocações-assíncronas)
- [Lambda Event Mapper Scaling](#lambda-event-mapper-scaling)
- [X-Ray tracing](#x-ray-tracing)
- [Layers](#layers)
- [File System](#file-system)
- [Concurrency and Throttling](#concurrency-and-throttling)
- [Preço](#preço)
- [Dependências](#dependências)
- [Container Images](#container-images)
- [Versions and Aliases](#versions-and-aliases)
- [Lambda \& CodeDeploy](#lambda--codedeploy)
- [Lambda Function URL](#lambda-function-url)
- [Limites por região](#limites-por-região)
- [.NET](#net)
  - [Configurar ambiente](#configurar-ambiente)
  - [Criar função](#criar-função)
  - [Deploy pelo CLI](#deploy-pelo-cli)
  - [Limpar ambiente](#limpar-ambiente)
- [Notas](#notas)

## Visão geral

- [Documentação AWS + .NET](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/lambda-csharp.html)
- [AWS Lambda begins](https://us-east-1.console.aws.amazon.com/lambda/home?region=us-east-1#/begin)
- Suporta async/await no manipulador
- Retornar `void` ou `Task` para processos assíscronos
- Retorno DTO para processos sincronos. O dado é serealizado em JSON.
- Utilizar source generator para diminuir uso de reflection na serialização e deserealizaão ([Tópico: Geração de origem para serialização JSON](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-handler.html#csharp-handler-types)).
- Suporta [top level statement](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-handler.html#top-level-statements).
- Alterar nível de log com a environment `AWS_LAMBDA_HANDLER_LOG_LEVEL`
- IAM policies para vincular a roles
  - AWSXRayDaemonWriteAccess: Para permitir tracing com x-ray
  - AWSLambdaBasicExecutionRole: Para permitir criar log group, log stream e enviar logs
- X-Ray não rastreia todas as operações, segundo [documentação](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-tracing.html): "A taxa de amostragem é uma solicitação por segundo e 5% de solicitações adicionais"
- [Compilação .NET AOT](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/dotnet-native-aot.html)
    - Necessário estar no Linux para realizar este deploy
    - Instalar [libraries no linux para linker de publish AOT](https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/).
- [.NET containerized](https://www.c-sharpcorner.com/article/deploy-net-lambda-functions-as-containers/)
- Para agendamento de execuções, use CloudWatchEvents
- Armazenamento em disco temporário no path **/tmp**
  - Conteúdo pode ser utilizado entre multiplas execuções do mesmo contexto, mas é descartado junto com a lambda quando ficar ociosa
  - 512 Mb de espaço

## Network

- Por padrão lambda são implantadas fora da sua VPC, possuem acessoa internet, mas não a recursos na sua VPC (Ex.: RDS)
- Lambda na VPC
  - Para a lambda funcionar com a rede privada e acesso a internet é necessário configurar NAT Gateway conforme [tutorial](https://nodogmablog.bryanhogan.net/2022/06/accessing-the-internet-from-vpc-connected-lambda-functions-using-a-nat-gateway/) (Nat Gateway + Route Tables + Internet Gateway).
  - Para acessar serviços gerenciados como DynamoDb / S3 sem fazer um salto na internet, é necessário configurar **VPC Endpoint** na rede privada
  - A lambda precisa de permissão para criar Elatic Network Interface na IAM Role (Policy: AWSLambdaENIManagementAccess)

# Performance

- **RAM**
  - de 128 MB até 10 GB
  - Quanto mais RAM, mais vCPU
  - Com 1792 MB a função possui o equivalente a 1 vCPU
    - Após isso, para se beneficiar por ter mais de 1 vCPU é necessário código multi-thread
- Timeout default 3 segundos, podendo ser incrementado até 900 segundos (15 minutos)
- Código comuns entre contextos diferentes não devem estar no function handlers (Ex.: conexão com banco, configuração de http client)

### Terraform

- O terraform não faz o build/publish da aplicação, antes do `terraform apply` execute o script `publish.sh` para publicar a aplicação e gerar o arquivo `publish.zip` (Binários ficam na raiz do zip)
- O módulo "archive_file" copia o arquivo para para `output_path` ou gera um zip neste local

## Invocações sincronas

### HTTP

- ALB possui a configuração "HTTP headers and query string parameters that are sent with multiple values" que habilita o encaminhamento como array do item com multiplo valor.
- Através do target group o ALB executa a lambda

## Invocações assíncronas

- S3, SNS, CloudWatch events, Code Commit, Code Pipeline, SES, Cloud Formation, Config, IoT, IoT events
- Fila de events interna
- Padrão: Tenta executar até 3 vezes em caso de falhas (3 vezes total)
  - 1 minuto após primeira falha
  - 2 minutos após segunda falha
  - Pode definir um SQS DLQ para as falhas
  - Todas as invocações possuem o mesmo request id
- Ao invocar receber status code 202 (Accpeted)
  - Se o código disparar exception, receberá o código 202 e deverá investigar detalhes no cloud watch logs
- Para definir a invocação assincrona vá em Configuration / Asynchronous invocation

## Lambda Event Mapper Scaling

- Kinesis Data Streams & DynamoDB Streams
  - Uma lambda invocation por shard
  - Se paralelizar, pode processar até 10 batchs por shard simultaneamente
- SQS Standard
  - Adicionar 60 instâncias por minuto
  - Até 1000 batchs são processadas simultâneamente
- SQS FIFO
  - Mensagens com mesmo group ID são processadas em ordem
  - Pode escalar até a quantidade de grupos de mensagens

## X-Ray tracing

- Envrionment variables
  - _X_AMZN_TRACE_ID: Tracind header
  - AWS_XRAY_CONTEXT_MISSING: by default, LOG_ERROR
  - AWX_XRAY_DAEMON_ADDRESS: X-Ray daemon IP_DDRESS:PORT

## Layers

Dois são os principais casos de uso:

- Fornecer compatibilidade com runtime não suportado oficialmente (Ex.: C++, Rust)
- Empacotar dependências e agilizar deploy do código que frequentemente é alterado

## File System

- Pode acessar EFS em execução na VPC
  - Configurar ponto de montagem do diretório
  - Necessário EFS Access Point
  - Cuidado com o limite de conexões do EFS


## Concurrency and Throttling

- Até 1000 execuções concorrentes
- Boa prática: Limitar execuções concorrentes
- Se ultrapassar limites:
  - Execuções sincronas: retornar ThrottleError - 429
  - Execuções assincronas: retry automático e envio para DLQ
- Os limites são na account, uma lambda com muito acesso simultâneo pode gerar ThrottleError para outra
- S3 events
  - Para erros do tipo 429 (Throttle) e 5XX, a Lambda retorna o evento para fila e tentará reprocessar por até 6 horas
  - Intervalo entre tentativas exponencial de 1 segundo até no máximo 5 minutos

## Preço

- [Estimativas](https://calculator.aws/#/estimate?id=40da936de5afe333d8505a2fd57f66dd89440a87)
- [Como é realizada a cobrança](https://docs.aws.amazon.com/pt_br/whitepapers/latest/how-aws-pricing-works/lambda.html)
- **Free tier:** 1 milhão de requisições por mês e 400 GB de tráfego
- Após free tier, $ 0.20 por milhão de requisição mensal

## Dependências

- Necessário empacotar todas as dependências junto no pacote zip para upload
- Se ultrapassar 50 Mb é necessário subir o zip para S3 e referência-lo na lambda
- Bibliotecas nativas do Amazon Linux não precisam ser empacotadas
- AWS SDK não precisa ser empacotado

## Container Images

- Até 10 Gb no ECR
- Base imagem deve implementar Lambda Runtime API (Ex.: public.ecr.aws/lambda/dotnet:6)
  - Disponívels para Python, Node.js, Java, .NET, Go, Ruby

## Versions and Aliases

- $LATEST: Versão em desenvolvimento (A que é alterada no console/ultimo deploy)
- Após validada, pode-se gerar a versão imutável (v1, v2, v3, etc)
  - Versão = Código + configuração (imutáveis)
- Cada versão pode ser utilizada
- Aliases são apenas ponteiros para versões
  - Sâo mutáveis
  - Ex.: prod = v1, dev = v2
  - São utilizados para Canary Deployment
  - Alias pode apontar para duas versões e possuir configuração de peso para o balanceamento

## Lambda & CodeDeploy

- Aplica lógica incremental nos pesos do alias para troca de versão
  - Linear: Aumentar tráfego a cada X minutos até 100% (Linear10PercentEvery3Minutes, Linear10PercentEvery10Minutes)
  - Canary: Aumentar tráfego em X percento até 100% (Canary10Percent5Minutos, Canary10Percent30Minutes)
  - AllAtOnce: Imediato

## Lambda Function URL

- URL dedicada para o endpoint
  - https://\<url-id\>.lambda-url.\<region\>.on.aws
  - Permanece sempre a mesma para o alias
- Acesso pela internet pública
  - Não suporta link privado
- Throttle by Reserved Concurrency
- Suportar CORS
- Autenticação IAM ou nenhuma


## Limites por região

- Execution
  - Memória: 128 mb - 10 gb
  - Tempo máximo: 900 segundos (15 minutos)
  - Environment variables: 4 kb
  - Temporary space (/tmp): 512 mb - 10 gb
  - Concurrency executions: 1000 (pode ser incrementado com chamado)
- Deployment
  - Max size .zip: 50 mb (Descomprido 250 mb)
  - Pode usar diretório /tmp para manipular arquivos

## .NET

- JIT: Just In Time. Linking e conversão para instrução nativa do SO ocorre em tempo de execução. O binário gerado pelo `dotnet build` é multi plataforma.
- AOT: Ahead Of Time. Compilado antecipa processo de linking e gera o binário nativo para o SO. O binário gerado pelo `dotnet build` é específico para a plataforma indicada (linux, windows, x86_64, arm64).

### Configurar ambiente

- [CLI do .NET Core](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-package-cli.html)
- [Visual Studio Code](https://github.com/aws/aws-lambda-dotnet/tree/master/Tools/LambdaTestTool)
- [Visual Studio](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-package-toolkit.html)

Instalar templates:

```bash
dotnet new -i Amazon.Lambda.Templates

# Listar
dotnet new --list | grep AWS

# Help do template
dotnet new lambda.EmptyFunction --help
```

Instalar pacote de ferramentas para deploy `Amazon.Lambda.Tools`:

```bash
dotnet tool install -g Amazon.Lambda.Tools

# Para atualizar
dotnet tool update -g Amazon.Lambda.Tools
```

**Configurar [Visual Studio Code debugger](https://github.com/aws/aws-lambda-dotnet/tree/master/Tools/LambdaTestTool)**:

```bash
# De acordo com seu runtime
dotnet tool install -g Amazon.Lambda.TestTool-8.0
dotnet tool install -g Amazon.Lambda.TestTool-7.0
dotnet tool install -g Amazon.Lambda.TestTool-6.0
```

Criar configuração no arquivo [.vscode\launch.json](..\.vscode\launch.json) para inicializar debugger.

Para deploy AOT

```bash
# Ubuntu
sudo apt-get install clang zlib1g-dev

# Alpine
sudo apk add clang build-base zlib-dev
```

### Criar função

```bash
dotnet new lambda.EmptyFunction --name MyFunction
```

### Deploy pelo CLI

Deploy function to AWS Lambda:

```bash
# Fazer assim na primeira vez para configurar atributos para criação da ROLE IAM
dotnet lambda deploy-function

# Para atualizar
dotnet lambda deploy-function \
    --function-name <function-name> \
    --function-role <function-iam-role> \
    --function-handler <novo-function-handler> # sobrescrever configuração do arquivo aws-lambda-tools-defaults.json \
    --tracing-mode <PassThrough or Active> # ativar x-ray
```

Invocar lambda:

```bash
aws lambda invoke --function-name <function-name> out \
    --log-type Tail \
    --cli-binary-format raw-in-base64-out \
    --payload '"aaa"' \
    --query 'LogResult' \
    --output text |  base64 -d
```
### Limpar ambiente

Recursos para apagar em caso de testes manuais:

- Lambda function
- Cloud watch / Log group
- IAM / Role

## Notas

Lambda deploy

```bash
# Deploy
dotnet lambda deploy-function --function-name simple-function --function-role simple-function-lambda --tracing-mode Active
dotnet lambda deploy-function --function-name context-details --function-role context-details-lambda --tracing-mode Active
dotnet lambda delete-function --function-name simple-function
dotnet lambda delete-function --function-name context-details


dotnet lambda deploy-function --function-name simple-function-aot --function-role simple-function-aot-lambda --tracing-mode Active

# Executar
aws lambda invoke --function-name context-details out \
    --log-type Tail \
    --cli-binary-format raw-in-base64-out \
    --payload '"aaa"' \
    --query 'LogResult' \
    --output text |  base64 -d
```

dotnet publish

```bash
dotnet publish -c Release -o publish --framework net6.0 -r linux-x64 -p PublishReadyToRun=true --no-self-contained

dotnet publish -c Release -o publish --framework net7.0 -r linux-x64

```



Trusted entities
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}