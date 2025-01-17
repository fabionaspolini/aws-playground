# AWS Playground

- [Visão geral](#visão-geral)
- [Serviços](#serviços)
- [Pré requisitos](#pré-requisitos)
- [Setup inicial](#setup-inicial)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Alternativa com Localstack](#alternativa-com-localstack)
- [CLI](#cli)

## Visão geral

Repostório com exemplos de uso da stack AWS.

Focado no gerenciamento de recursos através de terraform e código fonte C#.

Em alguns exemplos também existem os comandos por AWS CLI.

- **[docs/terraform](docs/terraform.md)**
- **[docs/aws](docs/aws.md)**
- [Documentação oficial AWS.](https://docs.aws.amazon.com/index.html)
- [Página oficial Terraform.](https://www.terraform.io/)
- [Documentação do provider AWS para Terraform.](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Lista de serviços de banco de dados gratuitos](https://aws.amazon.com/pt/free/database/)
- [Lista com todos serviços gratuitos](https://aws.amazon.com/pt/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=categories%23databases)


## Serviços

Neste repositório o foco é apenas no recurso unitário da AWS. Haverá muita duplicidade de código terraform e .net.

- [API Gateway](services/apigatey)
- [Athena](services/athena)
- [Cloud Front](services/cloudfront)
- [Cloud Watch](services/cloudwatch)
- [DynamoDB](services/dynamodb)
- [EC2](services/ec2)
- [Glue](services/glue)
- [Kinesis](services/kinesis)
- [Lambda](services/lambda)
  - [Benchmarks](services/lambda-benchmark)
- [RDS](services/rds)
- [S3](services/s3)
- [SQS](services/sqs)
- [Step Function](services/step-function)
- [VPC](services/vpc)

## Pré requisitos

1. Conta AWS previamente criada
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado em seu computador
3. [Access Key e Secret Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) geradas para configurar o profile default do CLI
3. CLI configurada para sua account (Executar `aws configure` no terminal)
4. Configurar variável de ambiente `AWS_ACCOUNT_ID` com o código da sua conta.
    - Varável utilizada apenas para configurar backend do terraform, pois não é possível utilizar as variáveis internas do TF neste local.

Informações adicionais:

- Todos os exemplos são na region `us-east-1`.
- Nenhum exemplo possui as credenciais de acesso a account AWS, isso é obtido do profile default configurado no passo 3.
- Por convenção quando não informado os parâmetros de acesso a account AWS, as bibliotecas utilizam as credenciais configurada nas variáveis de ambiente ou no profile default (Arquivo *~./.aws/credentials*).
- Todas os comandos de CLI apresentados são na syntax do bash (Se estiver utilizando Windows, utilize o git bash para executa-los).

## Setup inicial

O terraform precisa armazenar o estado dos recursos gerenciados após cada execução de comando (arquivo tfstate).  
Neste exemplo utilizaremos um bucket S3 para armazenar o arquivo.

Crie manualmente pelo AWS CLI:

```bash
aws s3api create-bucket \
    --region us-east-1 \
    --bucket "terraform-state-$(aws sts get-caller-identity --query "Account" --output text)"

aws s3api put-bucket-tagging \
    --region us-east-1 \
    --bucket "terraform-state-$(aws sts get-caller-identity --query "Account" --output text)" \
    --tagging "TagSet=[{Key=managed-by, Value=manual}]"
```

Todos as outras stacks a partir daqui, serão criadas e gerenciadas pelo terraform e armazenarão o tfstate no bucket acima.

Obs.: Nomes de bucket são únicos por região, por isso adicionamos o comando `aws sts get-caller-identity --query "Account" --output text` para concatenar o ID da sua account ao nome do bucket.

## Estrutura do repositório

Cada subpasta possui a estrutura `infra` com o código terraform e a pasta `src` com o código C#.

```
|── services                ⫸ Serviços testados de forma simples, sem muita relação forte de outros componentes AWS
|   └── aws-service-name    ⫸ Nome do serviço sendo avaliado
|       │── [+] infra       ⫸ Código terraform para gerenciamento da infra
|       │── [+] src         ⫸ Código C# utilizando o recurso
|       └── README.md       ⫸ Instruções e informações específicas do serviço. A ultima seção "Notas" é um bloco de anotações com comandos completos, sem abstrações.
└── stacks                  ⫸ Projeto completo com serviços relacionados e toda infraestrutura necessária para contruir uma aplicação
    └── [+] shared          ⫸ Recursos compartilhados, como: VPC, subnet, IAM policies, entre outros
```

Para provisionar os recursos na AWS, acesso a pasta infra pelo console e digite:

```bash
# Fazer download dos módulos. Apenas necessário quando vinculado novos módulos/providers externos.
terraform init -backend-config="bucket=terraform-state-${AWS_ACCOUNT_ID}"

# Para criar/modificar
terraform apply -auto-approve

# Para destruir
terraform apply -auto-approve -destroy

# Limpeza total
apply-all.sh -destroy
```

## Alternativa com Localstack

[Localstack](https://localstack.cloud/) é um projeto para emular na máquina local alguns serviços AWS.  
Deve ser utilizado apens como ambiente de testes do desenvolvedor. Nunca em produção!

> Obs.: Exemplos do terraform não são compatíveis com localstack, apenas por CLI e aplicação.

Para subir a stack pelo Docker:

```bash
docker run -d \
    --name localstack \
    -p 4566:4566 \
    -p 4510-4559:4510-4559 \
    localstack/localstack
```

Para facilitar o uso, crie o alias `awslocal` no bash para direcionar comandos ao aws cli com o parâmetro `--endpoint-url=http://localhost:4566`.

```bash
# Editar .bashrc (ou .bash_profile, veja o que existe no seu ambiente)
nano ~/.bashrc

# Adicionar alias
alias awslocal="AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1 aws --endpoint-url=http://${LOCALSTACK_HOST:-localhost}:4566"

# Recarregar configurações
source ~/.bashrc

# Testar
awslocal s3 ls  # Não deve listar nada após subir stack
aws s3 ls       # Deve listar bucket "terraform-state-<account-id>" real na AWS que criamos anteriormente
```

O site [https://app.localstack.cloud](https://app.localstack.cloud/) oferece recursos visual para gestão do seu localstack.  
Na página de [status](https://app.localstack.cloud/status) é possível ver o que está em uso. Os recursos são iniciandos on demand, ou seja, somente ao utiliza-lo será atualizado o status *running*.  
Clique em ***resources*** para acessar os detalhes do mesmo.

> Obs.: Todas as documentações presentes neste repositório estão apontando para o aws cli oficial, gerindo recursos na AWS.  
> Substitua `aws` ou `awslocal` para utilizar o localstack.  
> Também é possível apontar o terraform para o localstack, mas nenhum exemplo daqui tratará isso.

## CLI

- `--no-cli-pager`: Imprimir resultado completo no console sem interação do usuário.
