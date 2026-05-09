# ============================================================================
# ECS Fargate
# ----------------------------------------------------------------------------
# 3 つの ECS サービスを定義:
#   1. backend  : Rails API（ALB から /api/* と /up を受ける）
#   2. sidekiq  : Sidekiq ワーカー（ALB なし、Redis から job を取り出す）
#   3. frontend : Next.js（ALB から / 系を受ける）
#
# 最小構成のため Fargate Spot は使わず通常 Fargate。デプロイ時間短縮のため
# サーキットブレーカ（自動ロールバック）を有効化。
# ============================================================================

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled" # 最小構成（CloudWatch コストを抑制）
  }
}

# ====================================================================
# Backend (Rails) Task Definition
# ====================================================================
resource "aws_ecs_task_definition" "backend" {
  family                   = "${local.name_prefix}-backend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.backend_cpu
  memory                   = var.backend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "backend"
    image     = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    environment = [
      { name = "RAILS_ENV", value = "production" },
      { name = "DATABASE_URL", value = "postgres://postgres:${urlencode(random_password.db_master.result)}@${aws_db_instance.main.address}:5432/${aws_db_instance.main.db_name}" },
      { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:6379/0" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "AWS_S3_BUCKET", value = aws_s3_bucket.assets.bucket },
      { name = "AWS_S3_ENDPOINT", value = "" }, # 本番は AWS S3 のため空（MinIO 用変数を流用）
      { name = "FRONTEND_ORIGINS", value = "http://${aws_lb.main.dns_name}" },
    ]
    secrets = [
      { name = "SECRET_KEY_BASE", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:SECRET_KEY_BASE::" },
      { name = "DEVISE_JWT_SECRET_KEY", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:DEVISE_JWT_SECRET_KEY::" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.backend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  lifecycle {
    # password の差分で毎回タスク定義が再作成されないように
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "backend" {
  name                   = "${local.name_prefix}-backend"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.backend.arn
  desired_count          = var.backend_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    # NAT を使わない構成のため public subnet + Public IP で起動
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.backend.arn
    container_name   = "backend"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# ====================================================================
# Sidekiq Task Definition
# ====================================================================
resource "aws_ecs_task_definition" "sidekiq" {
  family                   = "${local.name_prefix}-sidekiq"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "sidekiq"
    image     = "${aws_ecr_repository.backend.repository_url}:${var.backend_image_tag}"
    essential = true
    command   = ["bundle", "exec", "sidekiq"]
    environment = [
      { name = "RAILS_ENV", value = "production" },
      { name = "DATABASE_URL", value = "postgres://postgres:${urlencode(random_password.db_master.result)}@${aws_db_instance.main.address}:5432/${aws_db_instance.main.db_name}" },
      { name = "REDIS_URL", value = "redis://${aws_elasticache_cluster.main.cache_nodes[0].address}:6379/0" },
      { name = "AWS_REGION", value = var.aws_region },
      { name = "AWS_S3_BUCKET", value = aws_s3_bucket.assets.bucket },
    ]
    secrets = [
      { name = "SECRET_KEY_BASE", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:SECRET_KEY_BASE::" },
      { name = "DEVISE_JWT_SECRET_KEY", valueFrom = "${aws_secretsmanager_secret.app_secrets.arn}:DEVISE_JWT_SECRET_KEY::" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.sidekiq.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

resource "aws_ecs_service" "sidekiq" {
  name                   = "${local.name_prefix}-sidekiq"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.sidekiq.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

# ====================================================================
# Frontend (Next.js) Task Definition
# ====================================================================
resource "aws_ecs_task_definition" "frontend" {
  family                   = "${local.name_prefix}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([{
    name      = "frontend"
    image     = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
    essential = true
    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]
    environment = [
      { name = "NODE_ENV", value = "production" },
      # フロントから API へは ALB 経由で /api を叩く（同一 ALB 配下）
      { name = "NEXT_PUBLIC_API_BASE", value = "http://${aws_lb.main.dns_name}/api/v1" },
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.frontend.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])
}

resource "aws_ecs_service" "frontend" {
  name                   = "${local.name_prefix}-frontend"
  cluster                = aws_ecs_cluster.main.id
  task_definition        = aws_ecs_task_definition.frontend.arn
  desired_count          = var.frontend_desired_count
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 3000
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  depends_on = [aws_lb_listener.http]

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}
