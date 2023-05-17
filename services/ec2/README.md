# EC2

## Setup chaves SSH

Necessário criar chave pública e private para conexão por SSH em seu computador.

```bash
# executar
ssh-keygen

# gerar no path
~/.ssh/aws/ec2-playground
```

Para conectar `ssh -i ~/.ssh/aws/ec2-playground ubuntu@<ip>`