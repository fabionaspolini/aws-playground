# Aplicar todas as stacks em paralelo (single &)
# ./apply-all.sh -destroy # destruir tudo
terraform -chdir="infra/ecs" apply -auto-approve $1 & \
terraform -chdir="infra/rds" apply -auto-approve $1