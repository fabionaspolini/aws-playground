# Lambda

[Documentação.](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/lambda-csharp.html)

- Suporta async/await no manipulador
- Retornar `void` ou `Task` para processos assíscronos
- Retorno DTO para processos sincronos. O dado é serealizado em JSON.
- Utilizar source generator para diminuir uso de reflection na serealização e deserealizaão ([Tópico: Geração de origem para serialização JSON](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-handler.html#csharp-handler-types)).
- Suporta [top level statement](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-handler.html#top-level-statements).

## .NET

### Configurar ambiente

- [CLI do .NET Core](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-package-cli.html)
- [Visual Studio](https://docs.aws.amazon.com/pt_br/lambda/latest/dg/csharp-package-toolkit.html)

Instalar templates:
```bash
dotnet new -i Amazon.Lambda.Templates
```

Listar templates:
```bash
dotnet new --list | grep AWS

# Help do template
dotnet new lambda.EmptyFunction --help
```

### Criar função

```bash
dotnet new lambda.EmptyFunction --name MyFunction
```

### Deploy pelo AWS CLI

Instalar `Amazon.Lambda.Tools`
```bash
dotnet tool install -g Amazon.Lambda.Tools

# ou para atualizar
dotnet tool update -g Amazon.Lambda.Tools
```

Deploy function to AWS Lambda
```bash
dotnet lambda deploy-function

# ou informando parâmetros
dotnet lambda deploy-function --function-name <function-name> --function-role <function-iam-role>
```

## Notas

```bash
dotnet lambda deploy-function --function-name simple-function --function-role simple-function-role
```