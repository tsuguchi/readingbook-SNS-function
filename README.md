# 読書管理 SNS

読書記録を共有するソーシャルネットワーキングアプリケーション。

## 機能

- 投稿（読書感想・レビュー）
- いいね（投稿・本・コメント）
- フォロー（公開アカウント=即時 / 非公開アカウント=リクエスト型）
- リポスト（単純 / 引用）
- 検索（ユーザー / 本 / 投稿 / タグ）
- プロフィール設定（公開・非公開切替、好きなジャンル、お気に入りの本など）
- 通知（プッシュ通知 + アプリ内通知）

## 技術スタック

| レイヤー | 技術 |
|---|---|
| フロントエンド | Next.js (App Router) + TypeScript + Tailwind CSS |
| バックエンド | Ruby on Rails (API) + PostgreSQL |
| 認証 | Devise + JWT |
| 検索 | PostgreSQL 全文検索（pg_search） |
| ジョブキュー | Sidekiq + Redis |
| ストレージ | Active Storage（本番 S3 / 開発 MinIO） |
| インフラ | Docker / AWS（本番） |

詳細は [技術スタック.md](技術スタック.md) を参照。

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [要件定義.md](要件定義.md) | 機能要件・非機能要件 |
| [技術スタック.md](技術スタック.md) | 採用技術と構成 |
| [ER図.md](ER図.md) | データモデル |
| [API設計.md](API設計.md) | REST API 仕様 |
| [画面遷移図.md](画面遷移図.md) | 画面遷移 |
| [ワイヤーフレーム.md](ワイヤーフレーム.md) | 画面ワイヤーフレーム |
| [環境構築.md](環境構築.md) | ローカル開発環境セットアップ |

## クイックスタート

### 必要環境

- Docker Desktop（WSL2 バックエンド推奨）
- PowerShell 7+

### セットアップ

```powershell
# 1. .env を準備
Copy-Item .env.example .env

# 2. シークレット生成（環境構築.md の手順 3.4 参照）

# 3. ビルド & 起動
docker compose up -d
```

| サービス | URL |
|---|---|
| フロントエンド | http://localhost:3010 |
| バックエンド API | http://localhost:3001 |
| MinIO コンソール | http://localhost:9001 |

詳細手順は [環境構築.md](環境構築.md)。

## ライセンス

未定（個人プロジェクト）
