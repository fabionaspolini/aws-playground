# RDS

- [Route Table (Tabela de Rotas)](#route-table-tabela-de-rotas)
- [NAT Gateway](#nat-gateway)
- [Comunicação Pública e Privada na AWS](#comunicação-pública-e-privada-na-aws)
- [Exemplo de Arquitetura com VPC](#exemplo-de-arquitetura-com-vpc)


## Route Table (Tabela de Rotas)

Uma Route Table é um recurso que define as regras de roteamento dentro de uma VPC (Virtual Private Cloud).
Ela determina como o tráfego será roteado para dentro e fora da sub-rede.
Cada sub-rede em uma VPC deve estar associada a uma Route Table (pode ser a Route Table padrão ou uma customizada).


Funções principais:

- As Route Tables possuem entradas de rota que mapeiam intervalos de IP para destinos. Um destino pode ser:
  - Local (para comunicação dentro da VPC).
  - Internet Gateway (para sub-redes públicas, permitindo o tráfego de saída/entrada para a internet).
  - NAT Gateway (permitindo que sub-redes privadas possam acessar a internet sem que sejam diretamente acessíveis).
  - VPC Peering ou VPNs (para roteamento entre VPCs diferentes ou redes locais).

Exemplo básico de uma Route Table:

- Destino 10.0.0.0/16 (local): Isso permite comunicação interna dentro da VPC.
- Destino 0.0.0.0/0 (Internet Gateway): Isso permite tráfego para fora da VPC (internet).

Route Tables em sub-redes públicas e privadas:

- Sub-rede pública: Associada a uma Route Table que tem uma rota para um Internet Gateway (IGW), permitindo que instâncias (como um servidor web) possam se comunicar diretamente com a internet.
- Sub-rede privada: Associada a uma Route Table que não tem rota direta para o Internet Gateway. Geralmente, terá uma rota para um NAT Gateway, permitindo que essas instâncias façam requisições para a internet (ex.: atualizações de pacotes) sem estarem expostas diretamente.

## NAT Gateway

O NAT Gateway (Network Address Translation Gateway) permite que instâncias em uma sub-rede privada acessem a internet para
fazer requisições de saída (como atualizações de software ou chamadas de API),
mas impede que tráfego de entrada seja originado da internet diretamente para essas instâncias.

Como funciona:

- Sub-redes privadas: Por padrão, elas não têm acesso direto à internet, pois não estão associadas a um Internet Gateway.
  Se você precisa que essas instâncias façam chamadas de saída (por exemplo, para baixar atualizações ou acessar APIs externas), você precisa de um NAT Gateway.

- Sub-redes públicas: O NAT Gateway é provisionado em uma sub-rede pública com um Elastic IP atribuído.
 Quando uma instância em uma sub-rede privada faz uma solicitação para a internet, o tráfego passa pelo NAT Gateway,
 que altera o endereço IP de origem para o Elastic IP do NAT Gateway antes de enviar o tráfego à internet.
 A resposta segue o caminho inverso, permitindo a comunicação sem expor o IP privado da instância.


Exemplo de configuração:

1. A instância na sub-rede privada tenta acessar um repositório externo.
2. A solicitação é roteada para o NAT Gateway (através da Route Table da sub-rede privada).
3. O NAT Gateway encaminha a solicitação para a internet usando seu Elastic IP.
4. A resposta da internet passa pelo NAT Gateway e é enviada de volta à instância na sub-rede privada.

Essa configuração é útil para:

- Manter instâncias privadas fora de alcance direto da internet, melhorando a segurança.
- Garantir que essas instâncias possam fazer comunicação de saída para atualizar pacotes ou acessar recursos externos.

## Comunicação Pública e Privada na AWS

**Sub-rede Pública**

- Tem uma Route Table com uma rota 0.0.0.0/0 apontando para o Internet Gateway.
- Recursos dentro dessa sub-rede, como servidores web, podem receber e enviar tráfego da internet diretamente.
- Esses recursos precisam ter um Elastic IP ou um IP público para serem acessíveis da internet.

**Sub-rede Privada**

- Não tem uma rota direta para o Internet Gateway.
- Geralmente, as instâncias na sub-rede privada usam um NAT Gateway para acessar a internet para tráfego de saída (mas não recebem tráfego de entrada diretamente da internet).
- Elas não têm IPs públicos e só podem ser acessadas por meio de outra rede (como uma VPN, Direct Connect ou bastion host).

## Exemplo de Arquitetura com VPC

Imagine que você está configurando uma aplicação web com um banco de dados privado:

1. Sub-rede pública: Contém as instâncias EC2 que hospedam o servidor web. Elas têm IP público e uma rota para o Internet Gateway.
2. Sub-rede privada: Contém instâncias EC2 que rodam o banco de dados. Elas não têm IP público e usam um NAT Gateway para qualquer comunicação de saída que precisem realizar (como atualizações do sistema).
3. Route Table:
- Sub-rede pública: Rota para o Internet Gateway.
- Sub-rede privada: Rota para o NAT Gateway.

Essa configuração garante que o servidor web pode se comunicar diretamente com a internet, mas o banco de dados permanece protegido, sem exposição pública.