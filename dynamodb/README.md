# Cheat sheet

[AWS docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/CheatSheet.html)

```bash
aws dynamodb create-table \
    --table-name Venda \
    --attribute-definitions \
        AttributeName=Id,AttributeType=S \
        AttributeName=SK,AttributeType=S \
    --key-schema AttributeName=Id,KeyType=HASH AttributeName=SK,KeyType=RANGE \
    --table-class STANDARD \
    --billing-mode PAY_PER_REQUEST

aws dynamodb put-item --table-name Vendas --item "file://payloads/put-01-header.json"
aws dynamodb put-item --table-name Vendas --item "file://payloads/put-01-items.json"
aws dynamodb put-item --table-name Vendas --item "file://payloads/put-02-header.json"
aws dynamodb put-item --table-name Vendas --item "file://payloads/put-02-items.json"

aws dynamodb update-item \
    --table-name Venda \
    --key '{ "Id": { "S": "ec8b14d5-b372-47ae-a164-87071cd46e87"}, "AnoMes": { "S": "2023-04" } }' \
    --update-expression "SET #cliente.#nome = :newval" \
    --expression-attribute-names '{"#cliente": "Cliente", "#nome": "Nome"}' \
    --expression-attribute-values '{":newval":{"S":"Beltrano"}}'
```

# Overview

Base de dados serveless, NoSQL e orientada a documentos.  
Gerenciado pela AWS automaticamente e você apenas cria suas tabelas.

## Primary key

Definida durante a criação da tabela e deve ser pensada de forma a organizar seus dados de acordo com seu caso de uso.

Existem duas opções para compor a primary key, você informará o nome dos campos com os papéis:

- Opção 1: Partition key
- Opção 2: Partition key + Sort key

Em ambas opções, os dados são distribuidos pela partition key.  
Na segunda opção você consegue manter um conjunto de dados relacionados ao mesmo contexto de negócio agrupados, 
para ganhar performance ao recupera-los todos juntos se necessário.

**Exempo:** Vamos imaginar diferente cenário de uso para uma tabela de vendas com cabeçalho, itens e dados do pagamento.

O exemplo está ilustrado com número inteiros como ID para facilitar a leitura, mas devem ser guids na vida real.

**Caso de uso 1:** Imagine que o principal caso de uso é no setor de atendimento ao cliente,
sendo necessário obter todos os dados de uma venda previamente especificada.  
Neste cenário há alta demanda para consultar todos os dados de uma venda em específico.  

A PK ficaria:
- Partition key: id da venda
- Sort key: campo texto com o tipo da linha

Na sort key teriamos o tipo da nossa linha:

1. Para o cabeçalho. sort key = header
2. Com Array com os itens. Sort key = itens
3. Para informações de pagamento. Sort key = invoice

| partition | sort      |
|-----------|-----------|
| venda-1   | header    |
| venda-1   | itens     |
| venda-1   | invoice   |
| venda-2   | header    |
| venda-2   | itens     |
| venda-2   | invoice   |

**Caso de uso 2:** Agora imgine o principal caso de uso dessa tabela de vendas é um website acessado pelo cliente final.
Logo o caso de uso está fortemente vinculado a "vendas do usuário" e passa a ser interessante o particionamento de vendas por usuário.

A PK ficaria:
- Partition key: id do usuário
- Sort key: campo texto concatenando id da venda + tipo

| partition | sort              |
|-----------|-------------------|
| user-1    | venda-1#header    |
| user-1    | venda-1#itens     |
| user-1    | venda-1#invoice   |
| user-1    | venda-2#header    |
| user-1    | venda-2#itens     |
| user-1    | venda-2#invoice   |
| user-2    | venda-3#header    |
| user-2    | venda-3#itens     |
| user-2    | venda-3#invoice   |

Perceba que nem sempre é interessante nomear os campos a serem utilizado como partition/sort key visando alguma caracteristica da entidade.  
Neste segunto exemplo seriá mais lógico nomear apenas como `sk`. Nada impede de aplicar a mesma lógica na partition key.

## Dimensionamento

- On-demand: Você não se preocupa com nada
    - Cobrado por RRU (Read Request Units) e WRU (Write Resquet Units)
    - 2.5x mais caro que provisionado
    - Usar para carga de trabalho desconhecida ou trafego imprevisível
- Provisionado:
    - Autoscaling baseado em RCU (Read Capacity Units) e WCU (Write Capacity Units)
    - Capacity units é um número baseado na quatidade de requisições de leitura/escrita e tamanho médio dos documentos estimado.  
      Existe uma calculadora na página de criação da tabela.
    - Disponível no modo **free tier**.
    - Capcidade provisionada pode ser excedida temporariamente (Burst Capacity)
    - Se estourar "Burst Capacity", ocorrerá "ProvisionedThroughputExceededException"
    - WCU e RCU são divididos igual entre as partições da tabela
        - Se possuir 10 RCUs e 5 partições internadas na tabela, cada partição possuirá 2 RCU
    - ProvisionedThroughputExceededException é por partição

Alterações no modo de dimensionamento só podem ser realizadas a cada 24 horas.

Calculos
- RCU: Itens por segundo * (Tamanho KB / 4 KB)
- WCU: Itens por segundo * (Tamanho KB / 1 KB)

> O resultado da divisão *"Tamanho KB / unidade KB"* sempre será arredondado para cima.

Exemplo 12 requisições por segundo de 8 KB
- RCU eventual (metade do valor): 12 * (8 KB / 4 KB) / 2 = 12 WCU.
- RCU strongly                  : 12 * 2 * (8 KB / 4 KB) = 24 WCU.
- WCU standard                  : 12 * (8 KB / 1 KB) = 96 WCU.
- WCU transacional              : 12 * 2 * (8 KB / 1 KB) = 192 WCU.

### Free tier

[Página oficial](https://aws.amazon.com/pt/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=categories%23databases)

Limites:

- 25 unidades de leitura (RCU)
- 25 unidade de escrita (WCU)
- 25 Gb armazenamento
- Disponível para sempre

Para garantir o uso free tier em testes simples, desabilite o autoscaling e fixe um pequeno valor.

> Just be aware of the fact that:
> - 25 WCU is 25 writes per second for an item up to 1KB or 5 writes per second for an item up to 5KB etc.
> - 25 RCU is 50 reads per second for an item up to 4KB or 10 reads per second for an item up to 20KB etc.

## Read & Write

- *Strongly consistent read* deve ser especificada na query, custa duas vezes mais RCU e possui maior latência
- Batch operation
    - Paralelizado internamente
    - Parte do bath pode falhar, sendo necessário tratar o retorno e repetir os itens falhados (Ex.: Excedeu a capacidade provisionada no meio do lote)
    - Write batch
        - Até 25 put/delete por execução
        - Até 16 MB ou 400 KB por item
        - Não suportar UpdateItem
    - Get batch
        - Até 100 itens ou 16 MB
- Optimistic Locking
    - Utiliza condições para escrita
    - Utiliza um campo como controle de versão do registro

## Indices

- Local Secundary Index (LSI)
    - Permite filtrar por atributos diferentes da sort key
    - Obrigatório informar partition key no filtro
    - Até 5 por tabela
    - (Throttling) Utiliza RCUs e WCUs da tabela principal
    - Não pode ser adicionado após criação da tabela

- Global Secundary Index (GSI)
    - Funciona como chave primária alternativa (Nova partition + sort key)
    - Melhorar performance de query em atributos (non-key attributes)
    - (Throttling) Necessário provisionar mais RCUs/WCUs para o indice
        - Se estourar provisionamento por causa de acessos de escrita ao indice, a tabela principal também será limitada (throttled)
    - Pode ser incluído após criar tabela

- Todo campo a ser utilizado como index deve ser top-level attribute (String, Number, or Binary). [AWS Doc](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/SecondaryIndexes.html).
- Pode ser informação a projeção de propriedades
    - KEYS_ONLY: Somente Primary key
    - INCLUDE: PK + atribuos informados. Não funciona propriedades aninhadas no formato "subpropriedade.prop", mas é possível incluir toda a subpropriedade.
    - ALL: Tudo
- Não existem indices únicos além da Primary key
- Necessário informar manualmente o nome do indice a ser utilizado na consulta (query)

## DynamoDB Accelerator (DAX)

Cache em memória do Dynamo.

- Alta disponibilidade
- Totalmente gerenciado
- Resolve problemas de acesso a "Hot keys" (Muitas leituras de uma chave)
- TTL default de 5 minutos
    - Definido no parameter group
    - TTL de item e query
- Até 10 nós no cluster (Multi AZ)
- Vinculado a VPC e security group precisa acesso inbound nas portas 8111 e 9111.
- Irá gerar em endpoint específico, no código .net é necessário utilizar a classe `ClusterDaxClient` para acessa-lo
    - [AWS doc](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DAX.client.run-application-dotnet.03-GetItem-Test.html)

## DynamoDB Streams

- Formatos para escrita no stream:
    - KEYS_ONLY: Somente chave pk/sk
    - NEW_IMAGE: Versão do registro após modificação
    - OLD_IMAGE: Versão do registro antes da modificação
    - NEW_AND_OLD_IMAGES: Ambas versões
- Ao ativar, não são populados registros retroativos
- Adicionar trigger para lambda function ou Kinesis data stream

## Time To Live (TTL)

Recurso para deletar registro automaticmente definindo uma data de expiração.

- Não consume WCUs
- Number data type no formato "Unix Epoch timestamp"
- O Dynamos possui realiza duas operações
    - Primeiro executa o processo de scan e marcação dos itens como expirados
    - Segundo para efetivar o delete, executando o scan nos itens marcados como expirados e realizando a exclusão
- Itens expirados são deletados dentro de 24 horas
- Os itens expirados continuam aparecendo nas consultas
    - Filtre manualmente para remove-los
- Itens são deletados nos LSIs e GSIs
- Processo de delete também executa o stream

## Transactions

Capacidade de realizaroperações de insert/update/delte em uma ou mais tabelas de forma coordenada

- Provem ACID para operação
- Consome 2x WCUs e RCUs


## Security

- Acessível através de endpoint sem acesso a internet
- Integração com Identify Providers para geração de credencial temporária vinculada a uma role IAM de permissões restritas a uma tabela

# Modelo de dados

**Estrutura de relacionamento**

Venda
- Id
- Data
- Cliente
    - Id
    - Nome
- Itens (Array)
    - Id
    - Nome
    - Valor unitário
    - Quantidade
    - Valor total
- Valor total
- Pagamento
    - Metodo (Boleto, Cartão, Pix)
    - Valor
- ExpireOn

**Requisitos**

1. Precisa suportar grande volume de gravação
2. Precisa recuperar todos os detalhes de uma venda rapidamente
3: Precisa recuperar todas as vendas de um cliente rapidamente e exibir dados do cabeçalho e do pagamento
4: Nesta base de dados devem estar presentes somente os registros do último ano

**Decições**

- Primary key
    - Partition key por id da venda => Para requisito 1 e 2
    - Sort key para separarmos linhas do cabeçalho + pagamento e itens => Para requisito 3, separamos a gravação dos itens em outra linha para reduzir RCU na consulta de vendas do cliente
- Criar global secundary index (GSI) => Para requisito 3
    - Partition key: Cliente.Id
    - Sorting key: Igual da primary key
- Criar campo `ExpireOn` para ser utilizado no TTL. Definir com data da venda + 1 ano => Para requisito 4
- Ao final da modelagem, a base de dados não é totalmente focada na orientação a documentos. Separamos nosso documento em duas linhas pelo fator custo.


# Materiais de apoio

- [Nick Chapsas / Getting started with AWS DynamoDB in .NET](https://www.youtube.com/watch?v=GzyMqh3BBzk&ab_channel=NickChapsas)
- [.NET: Document model](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/DotNetSDKMidLevel.html)
- [PocoDynamo](https://github.com/ServiceStack/PocoDynamo): ORM for .NET
- [PocoDynamo post](https://dev.to/gsaadeh/a-better-way-to-work-with-aws-dynamodb-and-net-3fop)