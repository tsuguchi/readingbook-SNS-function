locals {
  # 全リソース名の共通プレフィックス
  name_prefix = "${var.project_name}-${var.environment}"

  # 共通タグ（providers.tf の default_tags でも自動付与されるが、Name タグは個別に設定）
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
  }
}
