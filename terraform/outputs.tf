output "alb_dns_name" {
  description = "ALB のパブリック DNS 名。アプリへのアクセス URL"
  value       = aws_lb.main.dns_name
}

output "app_url" {
  description = "アプリの URL（HTTP）"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecr_backend_repository_url" {
  description = "バックエンドイメージの push 先"
  value       = aws_ecr_repository.backend.repository_url
}

output "ecr_frontend_repository_url" {
  description = "フロントエンドイメージの push 先"
  value       = aws_ecr_repository.frontend.repository_url
}

output "rds_endpoint" {
  description = "RDS PostgreSQL のエンドポイント（host:port 形式）"
  value       = aws_db_instance.main.endpoint
}

output "rds_database_name" {
  description = "作成された DB 名"
  value       = aws_db_instance.main.db_name
}

output "redis_primary_endpoint" {
  description = "ElastiCache Redis のプライマリエンドポイント"
  value       = aws_elasticache_cluster.main.cache_nodes[0].address
}

output "s3_assets_bucket" {
  description = "Active Storage 用 S3 バケット名"
  value       = aws_s3_bucket.assets.bucket
}

output "secrets_db_password_arn" {
  description = "DB パスワードを保管している Secrets Manager の ARN"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "secrets_app_arn" {
  description = "アプリ秘密値を保管している Secrets Manager の ARN（手動で書き換える）"
  value       = aws_secretsmanager_secret.app_secrets.arn
}

output "ecs_cluster_name" {
  description = "ECS クラスタ名"
  value       = aws_ecs_cluster.main.name
}

output "vpc_id" {
  description = "作成された VPC の ID"
  value       = aws_vpc.main.id
}
