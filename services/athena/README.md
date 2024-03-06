# Athena

- Para executar queries é necessário criar um bucket S3 para processamento de resultados.

## Data sources

Fontes de dados para as queries, por padrão a conta vem com acesso ao *"AWS Glue Data Catalog"*, porém é possível incluir outras fontes, como:

- Bases de dados relacionais (PostgreSQL, MySQL, SQL Server, Oracle)
- NoSQL (DynamoDB, OpenSeearch, DucumentDB, Redis)
- Kafka
- Entre outras


## Exemplo

Para incluir partições na tabela glue, a forma mais simples é pelo Athena, através do comando:

### Adicionar partição

```sql
ALTER TABLE `municipios-por-uf` ADD IF NOT EXISTS
    PARTITION (uf = 'SC') LOCATION 's3://tables-ACCOUNT_ID/municipios-por-uf/SC/'
    PARTITION (uf = 'PR') LOCATION 's3://tables-ACCOUNT_ID/municipios-por-uf/PR/'
    PARTITION (uf = 'RS') LOCATION 's3://tables-ACCOUNT_ID/municipios-por-uf/RS/'
    PARTITION (uf = 'RO') LOCATION 's3://tables-ACCOUNT_ID/municipios-por-uf/RO/';
```

## Cheat Sheet

```sql
-- Alterar localização de glue table no S3
ALTER TABLE municipios SET LOCATION 's3://tables-ACCOUNT_ID/municipios/';
```
