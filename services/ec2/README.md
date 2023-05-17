# EC2

- [Setup](#setup)
  - [VMs para implatar](#vms-para-implatar)
  - [Chave SSH](#chave-ssh)

## Setup

Script `user_data.sh` é executado para configurar a VM automaticamente após a subida (Recurso da AWS).

Logs do setup da VM ficam no arquivo `/var/log/cloud-init-output.log`.

### VMs para implatar

Habilitar VMs no arquivo [locals.tf](infra/locals.tf).

### Chave SSH

Necessário criar chave pública e private para conexão por SSH em seu computador.

```bash
# executar
ssh-keygen

# gerar no path
~/.ssh/aws/ec2-playground
```

Para conectar `ssh -i ~/.ssh/aws/ec2-playground ubuntu@<ip>`