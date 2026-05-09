# ============================================================================
# RDS PostgreSQL
# ----------------------------------------------------------------------------
# 最小構成では Single-AZ + db.t4g.micro。
# - スナップショット保持: 1 日（最小）
# - Performance Insights: 無効（コスト削減）
# - パスワード: Secrets Manager から自動取得
# ============================================================================

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "${local.name_prefix}-db-subnet"
  }
}

resource "aws_db_parameter_group" "postgres" {
  name        = "${local.name_prefix}-pg16"
  family      = "postgres16"
  description = "Custom PG params"

  # 必要に応じてパラメータを追加（例：log_min_duration_statement = 1000）
}

resource "aws_db_instance" "main" {
  identifier             = "${local.name_prefix}-db"
  engine                 = "postgres"
  engine_version         = var.rds_postgres_version
  instance_class         = var.rds_instance_class
  allocated_storage      = var.rds_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true
  db_name                = "readingbook_${var.environment}"
  username               = "postgres"
  password               = random_password.db_master.result
  port                   = 5432
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.postgres.name
  multi_az               = var.rds_multi_az
  publicly_accessible    = false

  backup_retention_period = var.rds_backup_retention_days
  backup_window           = "17:00-18:00" # JST 02:00-03:00
  maintenance_window      = "sun:18:00-sun:20:00"
  copy_tags_to_snapshot   = true
  deletion_protection     = false # dev のみ。本番は true 推奨
  skip_final_snapshot     = true  # dev のみ。本番は false 推奨
  apply_immediately       = false

  # Performance Insights は無効（最小構成）
  performance_insights_enabled = false

  tags = {
    Name = "${local.name_prefix}-db"
  }

  lifecycle {
    # password は Secrets Manager 経由で管理するため、再生成による意図しない変更を防ぐ
    ignore_changes = [password]
  }
}
