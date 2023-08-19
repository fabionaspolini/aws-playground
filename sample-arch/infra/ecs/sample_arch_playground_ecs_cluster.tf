resource "aws_cloudwatch_log_group" "sample_arch_playground_ecs_cluster" {
  name              = "/aws/lambda/sample-arch-playground-ecs-cluster"
  retention_in_days = 1
}

resource "aws_ecs_cluster" "sample_arch_playground" {
  name = "sample-arch-playground"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.sample_arch_playground_ecs_cluster.name
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "sample_arch_fargate_spot" {
  cluster_name = aws_ecs_cluster.sample_arch_playground.name

  capacity_providers = ["FARGATE_SPOT", "FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 70
    capacity_provider = "FARGATE_SPOT"
  }
}
