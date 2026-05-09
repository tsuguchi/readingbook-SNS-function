# ============================================================================
# S3 - Active Storage 用バケット
# ----------------------------------------------------------------------------
# Rails の Active Storage（アバター画像や本のカバーなど）を保管する。
# ローカルでは MinIO で代用しており、本番ではこの S3 バケットを使う。
# ============================================================================

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "assets" {
  # バケット名はグローバルユニークなのでサフィックスを付与
  bucket = "${local.name_prefix}-assets-${random_id.bucket_suffix.hex}"
}

resource "aws_s3_bucket_public_access_block" "assets" {
  bucket = aws_s3_bucket.assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# 古いマルチパートアップロード断片を 7 日で削除（コスト抑制）
resource "aws_s3_bucket_lifecycle_configuration" "assets" {
  bucket = aws_s3_bucket.assets.id

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}
