# ============================================================================
# CloudWatch Logs
# ----------------------------------------------------------------------------
# ECS タスクの stdout/stderr を集約する。retention は 7 日（コスト抑制）。
# ============================================================================

resource "aws_cloudwatch_log_group" "backend" {
  name              = "/ecs/${local.name_prefix}/backend"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "sidekiq" {
  name              = "/ecs/${local.name_prefix}/sidekiq"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name_prefix}/frontend"
  retention_in_days = 7
}
