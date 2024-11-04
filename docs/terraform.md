# Terraform

- [Meta arguments](#meta-arguments)
- [Convenções](#convenções)
- [Cheat Sheet](#cheat-sheet)
  - [IP público do ambiente executando o TF](#ip-público-do-ambiente-executando-o-tf)

## Meta arguments

Argumentos disponíveis para todos os elmentos.

[Documentação.](https://developer.hashicorp.com/terraform/language/meta-arguments/count)

- depends_on
- count: expressão ? 1 : 0
- for_each
- provider
- lifecycle


## Convenções

| Elemento  | Convenção    | Exemplo                     |
|-----------|--------------|-----------------------------|
| Recursos  | `snake_case` | `aws_instance "web_server"` |
| Variáveis | `snake_case` | `variable "instance_type"`  |
| Outputs   | `snake_case` | `output "database_url"`     |
| Módulos   | `kebab-case` | `module "network-setup"`    |
| Arquivos  | `kebab-case` | `main.tf, network-setup.tf` |

## Cheat Sheet

### IP público do ambiente executando o TF

```terraform
data "http" "ip" {
  url = "https://ifconfig.me/ip"
}

output "ip" {
  value = data.http.ip.response_body
}
```
