# AWS Playground

## Pré requisitos

1. Conta AWS previamente criada
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado em seu computador
3. [Access Key e Secret Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) geradas para configurar o profile default do CLI
3. CLI configurada para sua account (Executar `aws configure` no terminal)
4. Configurar variável de ambiente `AWS_ACCOUNT_ID` com o código da sua conta.

Informações adicionais:

- Todos os exemplos são na regiona `us-east-1`.
- Nenhum exemplo possui as credenciais de acesso a account AWS, isso é obtido do profile default configurado no passo 3.
- Por convenção quando não informado os parâmetros de acesso a account AWS, as bibliotecas utilizam as credenciais configurada nas variáveis de ambiente ou o profile default (Arquivo *~./.aws/credentials*).

## Setup inicial

O terraform precisa armazenar o estado dos recursos gerenciados após cada execução de comando (Arquivo tfstate), em nosso exemplo utilizaremos um bucket S3 para armazenar o arquivo.

Este bucket iremos criar manualmente pelo AWS CLI (Utilize o git bash):

```bash
aws s3api create-bucket \
    --region us-east-1 \
    --bucket "terraform-state-$(aws sts get-caller-identity --query "Account" --output text)"

aws s3api put-bucket-tagging \
    --region us-east-1 \
    --bucket "terraform-state-$(aws sts get-caller-identity --query "Account" --output text)" \
    --tagging "TagSet=[{Key=managed-by, Value=manual}]"
```

Todos as outras stacks a partir daqui, serão criadas e gerenciadas pelo terraform, utilizando o bucket acima na configuração "backend".

Obs.: Nomes de bucket são únicos por região, por isso adicionamos o comando `aws sts get-caller-identity --query "Account" --output text` para concatenar o ID da sua account ao nome do bucket (Também poderia ser utilizada a variável de ambiente AWS_ACCOUNT_ID configurada previamente).

## Exemplos

- [DynamoDB](docs/DynamoDb.md)