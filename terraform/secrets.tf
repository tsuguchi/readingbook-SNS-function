# ============================================================================
# Secrets Manager
# ----------------------------------------------------------------------------
# - DB パスワード（terraform で自動生成）
# - JWT 秘密鍵 / SECRET_KEY_BASE（手動でローテーション）
# ============================================================================

# RDS マスターパスワード（自動生成、URL 安全な文字のみ使用）
resource "random_password" "db_master" {
  length  = 32
  special = true
  # RDS が許容しない記号を除外（@, /, ", スペース等）
  override_special = "!#$%&*()-_=+[]{}<>?"
}

resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${local.name_prefix}/db_password"
  description             = "RDS master password"
  recovery_window_in_days = 0 # destroy 時の即削除（dev 環境のみ）
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_master.result
}

# アプリの環境変数として注入する秘密値群
# 内容は手動で `aws secretsmanager update-secret` などで設定する
# キー：SECRET_KEY_BASE / DEVISE_JWT_SECRET_KEY
resource "aws_secretsmanager_secret" "app_secrets" {
  name                    = "${local.name_prefix}/app_secrets"
  description             = "Application-level secrets (Rails SECRET_KEY_BASE / DEVISE_JWT_SECRET_KEY)"
  recovery_window_in_days = 0
}

# 初期値（プレースホルダ）。本番運用時は手動で書き換える前提。
resource "aws_secretsmanager_secret_version" "app_secrets_initial" {
  secret_id = aws_secretsmanager_secret.app_secrets.id
  secret_string = jsonencode({
    SECRET_KEY_BASE       = "REPLACE_ME_with_real_secret_via_aws_cli"
    DEVISE_JWT_SECRET_KEY = "REPLACE_ME_with_real_secret_via_aws_cli"
  })

  lifecycle {
    # 手動で更新した値を terraform apply で上書きしないため
    ignore_changes = [secret_string]
  }
}
