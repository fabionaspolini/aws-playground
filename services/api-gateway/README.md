# API Gateway

- [Visão geral](#visão-geral)
- [API Gateway - Integrations High Level](#api-gateway---integrations-high-level)
- [Tipos de endpoints](#tipos-de-endpoints)
- [Segurança](#segurança)

## Visão geral

Serviço para exposição de APIs sem gerenciamento de servidor.

Principais funcionalidades:

- AWS Lambda + API Gateway: Exposição de lambda como API sem gerenciamento de servidores.
- WebSocket.
- Versionamento de APIs (v1, v2...).
- Gerenciamento de ambientes (dev, test, prod...).
- Gerenciamento de seguração (autenticação e autorização).
- API keys para gerenciamento de cotas.
- Pode ser contruida importando arquivo Open API.
- Transformação e validação de requests e responses.
- Criação de SDK e especificações de APIs.
- Cache de respostas.

## API Gateway - Integrations High Level

**Lambda Function**

- Invocar lambdas.
- Caminho fácil para expor REST API baseados em lambdas.

**HTTP**

- Exposição de HTTP API on premisse, Application Load Balancer, etc.
- Motivo: Adicionar rate limit, cache, user authenticamente, api keys, etc... a serviços legados.

**Serviços AWS**

- Expor qualquer serviço AWS a partir do Gateway.
- Exemplo: Iniciar uma step function a partir de uma mensagem SQS postada diretamente do gateway.
- Motivo: Adicionar autenticação, rate limit, etc...

## Tipos de endpoints

**Edge-optimized (default)**

Para clientes globais, as requisições são roteadas através de **CloudFront Edge** locations para melhorar a latência.

O gateway está em apenas uma região, mas é acessível de forma eficiente a partir de cada local através do CloudFront Edge.

**Regional**

Para usuários na mesma região de criação do API Gateway.

Tecnicamente, acessível de qualquer lugar do mundo, porém sem otimizações de CDN oferecida pelo CloudFront Edge.

**Private**

Acessível somente de dentro da VPC, utilizando VPC endpoints (ENI).

Pode ser utilizado "resource policy" para definitir acessos ao gateway.


## Segurança

**Autenticação do usuário**

- IAM roles: Para aplicações internas (Ex.: EC2 acessando uma API).
- Cognito: Para usuários externos, como aplicativos mobile ou páginas web.
- Custom Authorizer: Lógica personalizada para outro Auth Server.

**Custom Domain Name HTTPS**

- Segurança através de certificado gerado pela AWS Certificate Manager (ACM).
  - Se utilizado Edge-Optimized endpoint, o certificado ficará em us-east-1.
  - Se utilizado Regional endpoint, o certificado ficará na mesma região.
  - Deve ser configurado o CNAME, A, ou ALIAS no Route 53.
