# Glue

- [Database](#database)
- [Tables](#tables)
- [S3 Data source](#s3-data-source)
- [Exemplo](#exemplo)
  - [Configurar bucket S3](#configurar-bucket-s3)
  - [Configurar Glue](#configurar-glue)

## Database

Utilizado para criar um agrupamento de dados, basicamente um descrição.  
As tabelas serão vinculadas ao database e nelas é que são configuradas as origem e formato de dados.

## Tables

Data sources:
- S3
- Kinesis
- Kafka

Data format:
- Avro
- CSV
- JSON
- Parquet
- ORC
- Grok

Cada linha do arquivo é considerado como um registro, portanto o formato **JSON** não pode estar formatado,
nem no com `[]` indicando multiplos registros.


## S3 Data source

Quando configurado um path, todas as subpastas serão consideradas.

## Exemplo

Neste exemplo serão adicionados arquivos num bucket S3 para simular os municípios brasileiros.

Uma pasta representará todos os arquivos agrupados, e em outra serão particionados por UF, para otimizar a leitura da informação por esta chave.

### Configurar bucket S3

- Criar bucket `tables-ACCOUNT_ID`
- Realizar upload dos arquivos da pasta:
  - [municipios](sample/municipios)
  - [municipios-por-uf](sample/municipios-por-uf)

Estrutura esperado no bucket:

```
|── municipios/
|   └── arquivos json
└── municipios-por-uf/
    └── PR
        └── arquivos json
    └── RO
        └── arquivos json
    └── RS
        └── arquivos json
    └── SC
        └── arquivos json
```

### Configurar Glue

- Criar database `s3-tables`
- Criar table `municipios`
  - Path: `s3://tables-ACCOUNT_ID/municipios/`
  - Schema:
    ```json
    [
        {
            "Name": "id",
            "Type": "int",
            "Comment": "Código IBGE"
        },
        {
            "Name": "nome",
            "Type": "string",
            "Comment": ""
        },
        {
            "Name": "uf",
            "Type": "string",
            "Comment": ""
        }
    ]
    ```
- Criar table `municipios-por-uf`, com campo UF atribuido como partition key
  - Path: `s3://tables-ACCOUNT_ID/municipios-por-uf/`
  - Schema:
    ```json
    [
        {
            "Name": "id",
            "Type": "int",
            "Comment": "Código IBGE"
        },
        {
            "Name": "nome",
            "Type": "string",
            "Comment": ""
        },
        {
            "Name": "uf",
            "Type": "string",
            "Comment": "",
            "PartitionKey": "Partition (1)"
        }
    ]
    ```
    - Adicionar "Partition indexes" pelo campo "uf"
    - Neste ponto, ao consultar a tabela, nenhum dado será retornado, pois não há partição anexada. Mesmo adicionando arquivos na raiz, os mesmo não serão identificados.
    - Adicione as partições através do [Athena](../athena/README.md#adicionar-partição)