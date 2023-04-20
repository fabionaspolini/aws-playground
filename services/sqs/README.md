# SQS

- [DLQ Workflow](#dlq-workflow)

## DLQ Workflow


No exemplo [infra/dlq-workflow.tf](infra/dlq-workflow.tf) é preservado o mesmo id de mensagem, evitando falsas estatíticas com re-publicações "progamadas" via código.

Fluxo da mensagem no código [src/dlq-workflow](src/dlq-workflow).

![dlq-workflow.png](assets/dlq-workflow.png)

Estado final da mensagem na fila dlq.

![dlq-workflow-02.png](assets/dlq-workflow-02.png)