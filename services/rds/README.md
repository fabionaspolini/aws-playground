# RDS

- [Visão geral](#visão-geral)
- [Stack](#stack)
- [Drivers .NET](#drivers-net)
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

## Stack

Habilitar stack no arquivo [locals.tf](infra/locals.tf).

## Drivers .NET

- [MySqlConnector](https://mysqlconnector.net/)
  - Suporta mulitplos server separados por virgula, porém não identifica qual é read-only
  - Quando falha uma operação de escrita por tentar enviar para uma instância rea only, ele tenta reenviar para
    outra conexão aperta no pool do driver. Porém esta também pode ser uma conexão read only e o comando de escrita é perdido
    (Isso é simulável com multi-thread / operações concorrentes).

## Anexos

- [Multi-master MySQL](https://aws.amazon.com/pt/blogs/database/building-highly-available-mysql-applications-using-amazon-aurora-mmsr/)
  - Atualmente (24/04/2023) está indisponível esta opção
