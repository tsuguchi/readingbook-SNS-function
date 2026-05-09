# Terraform state を S3 + DynamoDB（lock）で管理する場合の設定例。
#
# 初期は state がローカルのままで動かしたほうがシンプルなのでコメントアウトしてある。
# 複数人で運用する場合は以下を有効化し、事前に対象 S3 バケットと DynamoDB テーブルを
# 作成しておくこと（chicken-and-egg を避けるため初回は手動 or AWS CLI で作成）。
#
# terraform {
#   backend "s3" {
#     bucket         = "readingbook-sns-tfstate"
#     key            = "dev/terraform.tfstate"
#     region         = "ap-northeast-1"
#     dynamodb_table = "readingbook-sns-tflock"
#     encrypt        = true
#   }
# }
