# ============================================================================
# IAM ロール
# ----------------------------------------------------------------------------
# 1. Task Execution Role: ECS が ECR からイメージを pull したり、
#    Secrets Manager / SSM Parameter Store から環境変数を取得するために使う
# 2. Task Role: コンテナ内のアプリ自身が AWS API（S3 など）を呼ぶときに使う
# ============================================================================

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ---------- Task Execution Role ----------
resource "aws_iam_role" "ecs_task_execution" {
  name               = "${local.name_prefix}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Secrets Manager から secret を読む権限を Task Execution Role に追加
data "aws_iam_policy_document" "ecs_secrets_access" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.app_secrets.arn,
      aws_secretsmanager_secret.db_password.arn,
    ]
  }
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name   = "${local.name_prefix}-ecs-secrets-access"
  role   = aws_iam_role.ecs_task_execution.id
  policy = data.aws_iam_policy_document.ecs_secrets_access.json
}

# ---------- Task Role（アプリが S3 を読み書きするため） ----------
resource "aws_iam_role" "ecs_task" {
  name               = "${local.name_prefix}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_s3" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.assets.arn,
      "${aws_s3_bucket.assets.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "ecs_task_s3" {
  name   = "${local.name_prefix}-ecs-task-s3"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.ecs_task_s3.json
}
