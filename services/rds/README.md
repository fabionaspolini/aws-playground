# RDS

- [Visão geral](#visão-geral)
- [Free tier](#free-tier)
- [Stack](#stack)
- [Drivers .NET](#drivers-net)
- [Listar versões de engines](#listar-versões-de-engines)
- [Teste de atualização de configuração](#teste-de-atualização-de-configuração)
- [Anexos](#anexos)

## Visão geral

- Não possui endpoint para balancear automaticamente escrita/leitura ao cluster adequado.
  - Você precisa direcionar sua aplicação para o endpoint adequador (writer/reader)
  - Endpoint reader possui balanceamento entre N servidores de leitura
  - Endpoint writer não possui inteligência para direcionar consultar automaticamente ao reader
- Componente **RDS Proxy** não serve para balancer writer/reader de forma inteligente, apenas para criar um pool de conexões
  - Em geral, não é interessante usar com aplicações modernas .NET/Java que já possuem recursos nos conectores de banco para manter um pool de conxões abertas facilmente
  - Se torna interessante usar quando há muitas conexões de diversas instâncias de aplicações distintas sendo abertas frequentemente
- RDS disponibiliza a ferramenta **Performance Insights** para monitoramento do ambiente
  - Retenção de 7 dias em Free Tier
- Para adicionar replica do RDS é necessário ter backup configurado
- Espaço em disco mínimo: 20 Gb
- [Estimativa de custos](https://calculator.aws/#/estimate?id=84eb2d109731bb7d6b81bfe6280624cbc276c4d1)
- [Tipos de instâncias](https://aws.amazon.com/pt/rds/instance-types/)

## Free tier

12 MESES GRATUITOS

750 horas por mês de uso de instâncias de banco de dados mono-AZ db.t2.micro, db.t3.micro e db.t4g.micro (mecanismos de banco de dados aplicáveis).

20 GB de armazenamento de banco de dados de uso geral (SSD).

20 GB de armazenamento para backups de banco de dados e snapshots de bancos de dados.

[Fonte](https://aws.amazon.com/pt/free/database/)

## Stack

Habilitar stack no arquivo [locals.tf](infra/locals.tf).

## Drivers .NET

- [MySqlConnector](https://mysqlconnector.net/)
  - Suporta mulitplos server separados por virgula, porém não identifica qual é read-only
  - Quando falha uma operação de escrita por tentar enviar para uma instância rea only, ele tenta reenviar para
    outra conexão aperta no pool do driver. Porém esta também pode ser uma conexão read only e o comando de escrita é perdido
    (Isso é simulável com multi-thread / operações concorrentes).

## Listar versões de engines

```bash
aws rds describe-db-engine-versions --engine postgre --no-cli-pager
aws rds describe-db-engine-versions --engine aurora-postgresql --no-cli-pager
```

## Teste de atualização de configuração

| Ação                          | Aurora PG | RDS PG  |
|-------------------------------|-----------|---------|
| Aumentar tamanho disco        | n/a       | OK      |
| Reduzir tamanho disco         | n/a       |         |
| Alterar classe armazenamento  | n/a       |         |
| Atualizar engine version      | OK        |         |
| Atualizar instance size       | OK        |         |

**Roteiro RDS**

1. **Alterado de 20 Gb para 30 Gb (GP3):** OK, sem instabilidades e sem perda de dados.
2. **Alterado GP3 para GP2, com max storage 100 Gb:** Erro antes de 6 horas.

**Roteiro Aurora**

1. **Alterado engine de 15.2 para 16.4:** OK, com instabilidade e sem perda de dados.
2. **Alterado instance type de db.t4g.medium para db.t4g.large:** OK, com instabilidade e sem perda de dados.


## Anexos

- [Multi-master MySQL](https://aws.amazon.com/pt/blogs/database/building-highly-available-mysql-applications-using-amazon-aurora-mmsr/)
  - Atualmente (24/04/2023) está indisponível esta opção
