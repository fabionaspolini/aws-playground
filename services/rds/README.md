# RDS

- [Visão geral](#visão-geral)
- [Drivers .NET](#drivers-net)

## Visão geral

- Não possui endpoint para balancear automaticamente escrita/leitura ao cluster adequado.
  - Você precisa direcionar sua aplicação para o endpoint adequador (writer/reader)
  - Endpoint reader possui balanceamento entre N servidores
- Componente **RDS Proxy** não serve para balancer writer/reader de forma inteligente, apenas para criar um pool de conexões
  - Em geral, não é interessante usar com aplicações modernas .NET/Java que já possuem recursos nos conectores de banco para manter um pool de conxões abertas facilmente
  - Se torna interessante usar quando há muitas conexões de diversas instâncias de aplicações distintas sendo abertas frequentemente
- RDS disponibiliza a ferramenta **Performance Insights** para monitoramento do ambiente
  - Retenção de 7 dias em Free Tier
- [Estimativa de custos](https://calculator.aws/#/estimate?id=bf96eaad2ed00c6f65720cbc3f9b8b9afcb56dcd)

## Drivers .NET

- [MySqlConnector](https://mysqlconnector.net/)
  - Suporta mulitplos server separados por virgula, porém não identifica qual é read-only
  - Faz robin hood entre servidores
    - Nos comandos de escrita, envia para o read only, trata o erro e reenvia para o próximo server