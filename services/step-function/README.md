# Step Function

## Tipos

- Standard:
  - Para processos de longa duração;
  - Indicado para ETL, MK, jornadas de longa duranção do sistema (Ex.: Fluxo de pagamento do e-commerce), entre outros;
  - Workflows de até 1 ano;
  - Histórico step by step armazenado na própria step function;
    - Mesmo com log level `OFF`, são apresentadas as estatisticas de execuções/tracing.
- Express:
  - Para processos curtos;
  - Indicado para APIs, microserviços, processamento de dados, entre outros;
  - Workflows de até 5 minutos;
  - Custo baixo;
  - Histórico step by step carregado do CloudWatch Logs;
    - Só é apresentado estatística de execução e tracing se o log level for `ALL`.

## Relacionamentos

- CloudWatch logs: Para armazenamento dos logs de execução step by step;
  - Path padrão: `/aws/vendedlogs/states/*`.
- Role: Controle de permissionamento de acesso a recursos.

## Cobrança

- Standard:
  - Cobrança por transição de estado;
  - Free tier: 4.000 transições de estado por mês, para sempre;
  - 0,000025 USD por transição de estado;
  - Ex.: 1.000 execuções diárias, com 10 transições de estado = $ 7,50 mês.
- Express:
  - Cobrança por tempo de execução;
  - Cobrança por bloco de memória de 64 MB;
  - 0,000001 USD por execução + custos de tempo + RAM;
  - Ex.: 1.000 execuções diárias, com 1 segundo de duração e 64 MB = $ 0.06 mês.
- [Visualizar simulação](https://calculator.aws/#/estimate?id=ab02254089eefa81b29bbd743d724e3e2a0150f9)