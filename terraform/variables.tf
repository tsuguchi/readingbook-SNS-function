variable "project_name" {
  description = "プロジェクト名。すべてのリソース名のプレフィックスになる"
  type        = string
  default     = "readingbook-sns"
}

variable "environment" {
  description = "デプロイ環境（dev / staging / prod）。リソース名サフィックスとして使う"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "デプロイ先 AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type        = string
  default     = "10.10.0.0/16"
}

variable "availability_zones" {
  description = "サブネットを配置する AZ のリスト（最低 2 つ：ALB の Multi-AZ 要件）"
  type        = list(string)
  default     = ["ap-northeast-1a", "ap-northeast-1c"]
}

variable "public_subnet_cidrs" {
  description = "パブリックサブネット CIDR（ALB / ECS Fargate を配置）"
  type        = list(string)
  default     = ["10.10.0.0/24", "10.10.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "プライベートサブネット CIDR（RDS / ElastiCache を配置）"
  type        = list(string)
  default     = ["10.10.10.0/24", "10.10.11.0/24"]
}

# ====================================================================
# RDS PostgreSQL
# ====================================================================
variable "rds_instance_class" {
  description = "RDS インスタンスクラス。最小構成では db.t4g.micro を採用"
  type        = string
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "RDS 初期割当ストレージ（GB）。最小は 20"
  type        = number
  default     = 20
}

variable "rds_postgres_version" {
  description = "PostgreSQL バージョン"
  type        = string
  default     = "16.4"
}

variable "rds_multi_az" {
  description = "Multi-AZ を有効にするか。最小構成 (dev) では false 推奨"
  type        = bool
  default     = false
}

variable "rds_backup_retention_days" {
  description = "RDS 自動バックアップ保持日数（0 で無効化、コスト削減用）"
  type        = number
  default     = 1
}

# ====================================================================
# ElastiCache Redis
# ====================================================================
variable "redis_node_type" {
  description = "Redis ノードタイプ。最小構成では cache.t4g.micro"
  type        = string
  default     = "cache.t4g.micro"
}

# ====================================================================
# ECS Fargate
# ====================================================================
variable "backend_image_tag" {
  description = "バックエンド ECR イメージタグ。CI/CD 経由で上書きする想定"
  type        = string
  default     = "latest"
}

variable "frontend_image_tag" {
  description = "フロントエンド ECR イメージタグ"
  type        = string
  default     = "latest"
}

variable "backend_cpu" {
  description = "バックエンドタスクの CPU（256 = 0.25 vCPU）"
  type        = number
  default     = 256
}

variable "backend_memory" {
  description = "バックエンドタスクのメモリ（MB）"
  type        = number
  default     = 512
}

variable "frontend_cpu" {
  description = "フロントエンドタスクの CPU"
  type        = number
  default     = 256
}

variable "frontend_memory" {
  description = "フロントエンドタスクのメモリ（MB）"
  type        = number
  default     = 512
}

variable "backend_desired_count" {
  description = "バックエンドタスクの希望数。最小構成では 1"
  type        = number
  default     = 1
}

variable "frontend_desired_count" {
  description = "フロントエンドタスクの希望数"
  type        = number
  default     = 1
}

# ====================================================================
# 接続元 CIDR 制御
# ====================================================================
variable "alb_ingress_cidr" {
  description = "ALB に接続を許可する CIDR。デフォルトは全許可（0.0.0.0/0）"
  type        = string
  default     = "0.0.0.0/0"
}
