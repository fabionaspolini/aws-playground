# AWS Playground

Repostório com exemplos de uso da stack AWS.

Focado no gerenciamento de recursos através de terraform e código fonte C#.

Nas pastas de exemplos também são possíveis encontrar comandos via aws cli.

## Pré requisitos

1. Conta AWS previamente criada
2. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) instalado em seu computador
3. [Access Key e Secret Key](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_credentials_access-keys.html#Using_CreateAccessKey) geradas para configurar o profile default do CLI
3. CLI configurada para sua account (Executar `aws configure` no terminal)
4. Configurar variável de ambiente `AWS_ACCOUNT_ID` com o código da sua conta.
    - Varável utilizada apenas para configurar backend do terraform, pois não é possível utilizar as variáveis internar do TF neste local.

Informações adicionais:

- Todos os exemplos são na regiona `us-east-1`.
- Nenhum exemplo possui as credenciais de acesso a account AWS, isso é obtido do profile default configurado no passo 3.
- Por convenção quando não informado os parâmetros de acesso a account AWS, as bibliotecas utilizam as credenciais configurada nas variáveis de ambiente ou no profile default (Arquivo *~./.aws/credentials*).

## Setup inicial

O terraform precisa armazenar o estado dos recursos gerenciados após cada execução de comando (arquivo tfstate).  
Neste exempl utilizaremos um bucket S3 para armazenar o arquivo.

Crie manualmente pelo AWS CLI (Utilize o git bash para compatibilidade de syntax):

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

Cada subpasta possui a estrutura `infra` com o código terraform e a pasta `src` com o código C#.

Para provisionar os recursos na AWS, acesso a pasta infra pelo console e digite:

```bash
# Para criar/modificar
terraform apply -auto-approve

# Para destruir
terraform apply -auto-approve -destroy
```

Lista de exemplos:

- [DynamoDB](dynamodb/README.md)

## Alternativa com Localstack

[Localstack](https://localstack.cloud/) é um projeto para emular na máquina local vários serviços AWS.  
Deve ser utilizado apens como ambiente de testes do desenvolvedor. Nunca em produção!

> Obs.: Exemplos do terraform não são compatíveis com localstack, apenas por CLI e aplicação.

```bash
docker run -d \
    --name localstack \
    -p 4566:4566 \
    -p 4510-4559:4510-4559 \
    localstack/localstack
```

Criar alias `awslocal` para direcionar comandos ao aws cli com o parâmetro `--endpoint-url`
redirecionado para `http://localhost:4566`.

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
Na página de [status](https://app.localstack.cloud/status) é possível ver o que está em uso. Os recursos são iniciandos on demand, ou seja, somente ao utilizalo mudará para o status *running*.  
Clique em ***resources*** para acessar os detalhes do mesmo.

> Obs.: Todas as documentações presentes neste repositório estão apontando para o aws cli oficial, gerindo recursos na AWS. Substitua `aws` ou `awslocal` para utilizar o localstack.