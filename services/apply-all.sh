# Aplicar todas as stacks em paralelo (single &)
# ./apply-all.sh -destroy # destruir tudo
terraform -chdir="lambda/infra" apply -auto-approve $1 & \
terraform -chdir="dynamodb/infra" apply -auto-approve $1