# Aplicar todas as stacks em paralelo (single &)
# ./apply-all.sh -destroy # destruir tudo
terraform -chdir="dynamodb/infra" apply -auto-approve $1 & \
terraform -chdir="lambda/infra" apply -auto-approve $1 & \
terraform -chdir="lambda-benchmark/infra" apply -auto-approve $1