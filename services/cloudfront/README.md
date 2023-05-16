# CloudFront

- [Visão geral](#visão-geral)
- [Functions](#functions)

## Visão geral


## Functions

- Possibilidade de adicionar funções lambda ou cloud front functions para manipular
- Lambda suporta as operações:
  - Viewer request: Após CloudFront receber requisição do cliente
  - Origin request: Antes do CloudFront enviar requisição a origem
  - Origin response: Após CloudFront receber resposta da origem
  - Viewer response: Antes do CloudFront enviar resposta para cliente
- CloudFront functions suporta apenas viewer request/response
- CloudFront functions suporte apenas JavaScript functions, 2 MB de memória máxima, 10KB de tamanho e tempo máximo de execução menor que 1 ms
- Dono da função será us-east-1 e então CloudFront replica para outras localizações