# Lambda

[Documentação.](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/lambda-csharp.html)

- Suporta async/await no manipulador
- Retornar `void` ou `Task` para processos assíscronos
- Retorno DTO para processos sincronos. O dado é serealizado em JSON.
- Utilizar source generator para diminuir uso de reflection na serealização e deserealizaão ([Tópico: Geração de origem para serialização JSON](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-handler.html#csharp-handler-types)).
- Suporta [top level statement](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-handler.html#top-level-statements).
- Alterar nível de log com a environment `AWS_LAMBDA_HANDLER_LOG_LEVEL`
- IAM policies para vincular a roles
  - AWSXRayDaemonWriteAccess: Para permitir tracing com x-ray
  - AWSLambdaBasicExecutionRole: Para permitir criar log group, log stream e enviar logs
- X-Ray não rastreia todas as operações, segundo [documentação](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-tracing.html): "A taxa de amostragem é uma solicitação por segundo e 5% de solicitações adicionais"
- [Compilação .NET AOT](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/dotnet-native-aot.html)
- O terraform não faz o build/publish da aplicação, antes do `terraform apply` execute o script `publish.sh` para publicar a aplicação e gerar o arquivo `publish.zip` (Binários ficam na raiz do zip)
- O módulo "archive_file" copia o arquivo para para `output_path` ou gera um zip neste local

## .NET

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
dotnet tool update -g Amazon.Lambda.TestTool-6.0
dotnet tool update -g Amazon.Lambda.TestTool-7.0
```

Criar configuração no arquivo [.vscode\launch.json](..\.vscode\launch.json) para inicializar debugger.

### Criar função

```bash
dotnet new lambda.EmptyFunction --name MyFunction
```

### Deploy pelo AWS CLI

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
dotnet lambda deploy-function --function-name simple-function-context-details --function-role simple-function-context-details-lambda --tracing-mode Active
dotnet lambda delete-function --function-name simple-function
dotnet lambda delete-function --function-name simple-function-context-details

# Executar
aws lambda invoke --function-name simple-function-context-details out \
    --log-type Tail \
    --cli-binary-format raw-in-base64-out \
    --payload '"aaa"' \
    --query 'LogResult' \
    --output text |  base64 -d
```

dotnet publish

```bash
dotnet publish -c Release -o publish --framework net6.0 -r linux-musl-x64 -p PublishReadyToRun=true --no-self-contained
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