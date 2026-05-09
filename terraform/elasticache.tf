# ============================================================================
# ElastiCache Redis（Sidekiq + キャッシュ）
# ----------------------------------------------------------------------------
# 最小構成: cache.t4g.micro × 1 ノード（Single-AZ）
# 暗号化と認証は将来の本番化で有効化する
# ============================================================================

resource "aws_elasticache_subnet_group" "main" {
  name       = "${local.name_prefix}-redis-subnet"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_elasticache_cluster" "main" {
  cluster_id           = "${local.name_prefix}-redis"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.main.name
  security_group_ids   = [aws_security_group.redis.id]

  # メンテナンス時間（JST 03:00-05:00）
  maintenance_window = "sun:18:00-sun:20:00"

  tags = {
    Name = "${local.name_prefix}-redis"
  }
}
