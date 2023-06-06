# Terraform

- [Meta arguments](#meta-arguments)
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
