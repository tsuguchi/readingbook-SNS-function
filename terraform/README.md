# Terraform: 読書管理 SNS の AWS インフラ

このディレクトリには本プロジェクトを AWS にデプロイするための Terraform コード一式が含まれています。

> **重要**: コードは「**作成済み・未適用**」の状態です。`terraform apply` 実行は手動で行ってください。実行すると AWS 利用料金が発生します。

## 構成図

```
                     Internet
                        │
                        ▼
                 ┌─────────────┐
                 │  ALB (HTTP)  │  パブリック (Multi-AZ)
                 └─────┬───────┘
              /api/*   │   /
                ▼      ▼
       ┌─────────┐  ┌──────────┐
       │ Backend │  │ Frontend │  ECS Fargate (パブリック + Public IP)
       │ (Rails) │  │ (Next.js)│
       └────┬────┘  └──────────┘
            │
            │     ┌─────────┐
            │     │ Sidekiq │  ECS Fargate
            │     └────┬────┘
            │          │
       ┌────▼──────────▼──────┐
       │   VPC 内通信のみ        │  プライベートサブネット
       │   ┌──────┐  ┌──────┐  │
       │   │ RDS  │  │Redis │  │
       │   │ PG   │  │      │  │
       │   └──────┘  └──────┘  │
       └────────────────────────┘
```

## 月額コスト見積もり（最小構成、ap-northeast-1）

| リソース | スペック | 月額 (USD) |
|---|---|---|
| ALB | 1 台 | ~$18 |
| RDS PostgreSQL | db.t4g.micro Single-AZ + 20GB gp3 | ~$13 |
| ElastiCache Redis | cache.t4g.micro × 1 | ~$10 |
| ECS Fargate | 0.25 vCPU/0.5GB × 3 サービス（24h 起動） | ~$13 |
| ECR | リポジトリ ×2、~500MB | < $1 |
| S3 | < 1GB | < $1 |
| CloudWatch Logs | retention 7 日 | ~$2 |
| Secrets Manager | 2 シークレット | ~$1 |
| データ転送 | 数 GB/月 | ~$1 |
| **合計** | | **~$60 / 月** |

> NAT Gateway を使わない構成のため $32/月 を節約しています。本番化する際は private subnet + NAT Gateway もしくは VPC エンドポイントを推奨します。

## 含まれる AWS リソース

- VPC（CIDR 10.10.0.0/16）+ パブリック / プライベート 各 2 サブネット
- Internet Gateway、ルートテーブル
- セキュリティグループ 4 種（ALB / ECS / RDS / Redis）
- ECR リポジトリ × 2（backend / frontend）+ ライフサイクルポリシー
- IAM ロール × 2（タスク実行用 / タスクロール）
- Secrets Manager × 2（DB パスワード自動生成 / アプリ秘密値）
- RDS PostgreSQL 16（Single-AZ、暗号化）
- ElastiCache Redis 7
- S3 バケット（Active Storage 用、パブリックアクセス全ブロック、暗号化）
- ALB（HTTP リスナー、パスベースルーティング）
- ECS Fargate クラスタ + 3 サービス（backend / sidekiq / frontend）
- CloudWatch Log Group × 3

## 前提

- AWS アカウント
- AWS CLI v2 認証済み（`aws configure` または環境変数で IAM ユーザーを設定）
- Terraform >= 1.6
- Docker（イメージビルドと ECR push 用）

## 初回デプロイ手順

### 1. AWS 認証確認

```powershell
aws sts get-caller-identity
```

ARN とアカウント ID が表示されれば OK。

### 2. tfvars 準備

```powershell
cd terraform
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars  # 必要に応じて編集
```

### 3. Terraform 初期化

```powershell
terraform init
```

### 4. プラン確認（`apply` 前に必ず実行）

```powershell
terraform plan -out=plan.tfplan
```

差分とコスト影響を確認。

### 5. 適用

```powershell
terraform apply plan.tfplan
```

5〜10 分で完了。完了後に表示される `app_url` がアプリのアクセス URL（例: `http://readingbook-sns-dev-alb-xxx.elb.amazonaws.com`）。

### 6. シークレット値の本番化

初期値はプレースホルダのため、本番デプロイ前に置換が必要：

```powershell
# Rails の SECRET_KEY_BASE / DEVISE_JWT_SECRET_KEY を生成
$skb = (docker compose exec backend bundle exec rails secret).Trim()
$jwt = (docker compose exec backend bundle exec rails secret).Trim()

# Secrets Manager に書き込み
aws secretsmanager update-secret `
  --secret-id readingbook-sns-dev/app_secrets `
  --secret-string "{\"SECRET_KEY_BASE\":\"$skb\",\"DEVISE_JWT_SECRET_KEY\":\"$jwt\"}"
```

### 7. ECR にイメージを push

```powershell
# ECR ログイン
$account = (aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region ap-northeast-1 | `
  docker login --username AWS --password-stdin "$account.dkr.ecr.ap-northeast-1.amazonaws.com"

# Backend イメージ
docker build -t readingbook-sns-backend:latest -f backend/Dockerfile.production backend
docker tag readingbook-sns-backend:latest "$account.dkr.ecr.ap-northeast-1.amazonaws.com/readingbook-sns-dev-backend:latest"
docker push "$account.dkr.ecr.ap-northeast-1.amazonaws.com/readingbook-sns-dev-backend:latest"

# Frontend イメージ（本番用 Dockerfile を別途作成する必要あり）
# ...
```

### 8. ECS サービスを更新（イメージ反映）

```powershell
aws ecs update-service `
  --cluster readingbook-sns-dev-cluster `
  --service readingbook-sns-dev-backend `
  --force-new-deployment

aws ecs update-service `
  --cluster readingbook-sns-dev-cluster `
  --service readingbook-sns-dev-frontend `
  --force-new-deployment

aws ecs update-service `
  --cluster readingbook-sns-dev-cluster `
  --service readingbook-sns-dev-sidekiq `
  --force-new-deployment
```

### 9. DB マイグレーション

ECS Exec を使ってタスクに入る:

```powershell
$taskArn = (aws ecs list-tasks --cluster readingbook-sns-dev-cluster --service-name readingbook-sns-dev-backend --query "taskArns[0]" --output text)

aws ecs execute-command `
  --cluster readingbook-sns-dev-cluster `
  --task $taskArn `
  --container backend `
  --interactive `
  --command "bundle exec rails db:create db:migrate"
```

## 破棄手順（コスト停止）

```powershell
cd terraform
terraform destroy
```

**注意**: 以下の手動削除が必要な場合あり:
- S3 バケット内のオブジェクト（先に空にする必要あり）
- CloudWatch Log Group のログデータ

完全停止には数分かかります。

## ファイル構成

| ファイル | 内容 |
|---|---|
| `versions.tf` | Terraform / プロバイダのバージョン要件 |
| `providers.tf` | AWS プロバイダ設定 + デフォルトタグ |
| `backend.tf` | tfstate を S3 で管理する設定例（コメントアウト） |
| `variables.tf` | すべての入力変数 |
| `locals.tf` | 計算済みローカル値（name_prefix 等） |
| `network.tf` | VPC、サブネット、IGW、ルートテーブル |
| `security_groups.tf` | 4 種のセキュリティグループ |
| `iam.tf` | ECS Task / Task Execution ロール |
| `ecr.tf` | バックエンド・フロントエンドのリポジトリ |
| `secrets.tf` | DB パスワード自動生成 + アプリ秘密値プレースホルダ |
| `s3.tf` | Active Storage 用バケット |
| `rds.tf` | PostgreSQL Single-AZ |
| `elasticache.tf` | Redis Single-AZ |
| `alb.tf` | ALB + リスナー + ターゲットグループ |
| `cloudwatch.tf` | ログ グループ |
| `ecs.tf` | クラスタ + 3 タスク定義 + 3 サービス |
| `outputs.tf` | URL、エンドポイント、ARN の出力 |

## 本番化に向けた TODO

このコードは MVP / dev 用の最小構成です。本番運用に移す際は以下を順次有効化してください：

- [ ] `rds_multi_az = true`（HA 化）
- [ ] `rds_backup_retention_days = 7`（バックアップ）
- [ ] RDS の `deletion_protection = true`、`skip_final_snapshot = false`
- [ ] ALB に HTTPS リスナー追加（ACM 証明書）
- [ ] CloudFront + Route53（独自ドメイン）
- [ ] WAF（攻撃対策）
- [ ] NAT Gateway もしくは VPC エンドポイント（プライベート化）
- [ ] ECS タスクの auto scaling
- [ ] CloudWatch アラーム + SNS（運用監視）
- [ ] S3 versioning 有効化
- [ ] Secrets Manager の自動ローテーション
- [ ] Container Insights 有効化
- [ ] tfstate を S3 + DynamoDB で管理（`backend.tf` のコメント解除）

## トラブルシューティング

### `terraform plan` で AvailabilityZone エラー

`variables.tf` の `availability_zones` をリージョンに合わせて変更してください。

### ECS タスクが立ち上がらない

CloudWatch Logs `/ecs/readingbook-sns-dev/backend` を確認。多くの場合：

- ECR にイメージがまだ push されていない
- DB マイグレーション未実行
- Secrets Manager の値がプレースホルダのまま

### ALB の health check が失敗する

- backend の `/up` エンドポイントが返るか確認
- セキュリティグループで ALB → ECS の 3000 ポートが開いているか確認
