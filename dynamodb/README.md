# TL;DR

[Cheat sheet](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/CheatSheet.html)

```bash
aws dynamodb create-table \
    --table-name Venda \
    --attribute-definitions \
        AttributeName=AnoMes,AttributeType=S \
        AttributeName=Id,AttributeType=S \
    --key-schema AttributeName=AnoMes,KeyType=HASH AttributeName=Id,KeyType=RANGE \
    --table-class STANDARD \
    --billing-mode PAY_PER_REQUEST

aws dynamodb put-item \
    --table-name Venda \
    --item "file://infra/sample-put.json"

aws dynamodb update-item \
    --table-name Venda \
    --key '{ "Id": { "S": "3c95c725-275c-474a-a068-151f8219f294"}, "AnoMes": { "S": "2023-04" } }' \
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

Perceba que não é interessante nomear os campos a serem utilizado como partition e sort key visando alguma caracteristica da entidade.  
Uma prática é nomea-los simplesmente como `pk` e `sk`.

## Dimensionamento

- On-demand: Você não se preocupa com nada
- Provisionado:
    - Autoscaling baseado em "Capacity Units"
    - Capacity units é um número baseado na quatidade de requisições de leitura + escrita + tamanho médio dos documentos.  
      Existe uma calculadora na página de criação da tabela.
    - Disponível no modo **free tier**.

## Free tier

[Página oficial](https://aws.amazon.com/pt/free/?all-free-tier.sort-by=item.additionalFields.SortRank&all-free-tier.sort-order=asc&awsf.Free%20Tier%20Types=*all&awsf.Free%20Tier%20Categories=categories%23databases)

Limites:

- 25 unidade de escrita (WCU)
- 25 unidades de leitura (RCU)
- 25 Gb armazenamento
- Disponível para sempre

Para garantir o uso free tier em testes simples, desabilite o autoscaling e fixe um pequeno valor.

> Just be aware of the fact that:
> - 25 WCU is 25 writes per second for an item up to 1KB or 5 writes per second for an item up to 5KB etc.
> - 25 RCU is 50 reads per second for an item up to 4KB or 10 reads per second for an item up to 20KB etc.
