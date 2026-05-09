# 読書管理SNS API 設計書

[要件定義.md](要件定義.md) ／ [技術スタック.md](技術スタック.md) ／ [ER図.md](ER図.md) に基づく REST API 仕様を定義します。

---

## 0. サマリ

| 項目 | 内容 |
|---|---|
| プロトコル | HTTPS |
| スタイル | REST + JSON |
| ベース URL | `/api/v1`（URL パスバージョニング） |
| 認証 | JWT（`Authorization: Bearer <token>` または httpOnly Cookie） |
| 文字コード | UTF-8 |
| 日時形式 | ISO 8601（例: `2026-05-09T10:00:00+09:00`） |
| ページネーション | カーソル方式（`?cursor=...&limit=20`）を基本、検索一覧はオフセット併用 |
| API ドキュメント | rswag による OpenAPI 3.0 自動生成 |

---

## 1. 共通仕様

### 1.1 共通ヘッダ

| ヘッダ | 用途 |
|---|---|
| `Authorization: Bearer <JWT>` | 認証 |
| `Content-Type: application/json` | リクエスト |
| `Accept: application/json` | リクエスト |
| `X-Request-Id` | トレーシング（任意） |

### 1.2 成功レスポンス基本形

#### 単一リソース
```json
{
  "data": { /* リソース */ }
}
```

#### コレクション（カーソル）
```json
{
  "data": [ /* リソース配列 */ ],
  "meta": {
    "next_cursor": "eyJpZCI6MTIzfQ==",
    "has_more": true
  }
}
```

#### コレクション（オフセット）
```json
{
  "data": [ /* リソース配列 */ ],
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 153,
    "total_pages": 8
  }
}
```

### 1.3 エラーレスポンス形式

```json
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "入力内容に誤りがあります",
    "details": [
      { "field": "body", "message": "本文は必須です" }
    ]
  }
}
```

#### 主要エラーコード

| HTTP | code | 用途 |
|---|---|---|
| 400 | `BAD_REQUEST` | 不正リクエスト |
| 401 | `UNAUTHENTICATED` | 認証必要 |
| 403 | `FORBIDDEN` | 権限不足／ブロック関係 |
| 404 | `NOT_FOUND` | リソース未存在 |
| 409 | `CONFLICT` | 重複（例: 既にフォロー済み） |
| 422 | `VALIDATION_FAILED` | バリデーション違反 |
| 429 | `RATE_LIMITED` | レート制限 |
| 500 | `INTERNAL_ERROR` | サーバ内部エラー |

### 1.4 認可ポリシー（共通）

- 認証必須エンドポイントは未ログイン時 `401`
- 非公開アカウントの投稿に非フォロワーがアクセス → `403`
- ブロック関係 → 双方向で `404` を返す（存在を秘匿）
- 削除済みリソース（`deleted_at IS NOT NULL`）→ `404`

### 1.5 レート制限

| 操作 | 上限（参考値） |
|---|---|
| いいね（POST/DELETE） | 100 / 分 / ユーザー |
| フォロー（POST） | 60 / 分 / ユーザー |
| 投稿（POST） | 20 / 分 / ユーザー |
| 検索（GET） | 120 / 分 / ユーザー |

レート超過時は `429` + `Retry-After` ヘッダ。

---

## 2. リソース表現（共通スキーマ）

### 2.1 User

```json
{
  "id": 123,
  "handle": "yusaku_t",
  "display_name": "津口雄作",
  "avatar_url": "https://cdn.example.com/avatars/123.webp",
  "bio": "本を読むのが好きです",
  "is_private": false,
  "is_following": true,           // 閲覧者からのフォロー状態
  "follow_status": "ACCEPTED",    // ACCEPTED / PENDING / null
  "is_blocked": false,            // 閲覧者→対象 のブロック
  "is_muted": false,
  "counts": {
    "posts": 42,
    "followers": 120,
    "following": 80
  },
  "created_at": "2026-01-10T10:00:00+09:00"
}
```

非公開アカウントを非フォロワーが取得した場合は `counts` を省略（または 0）し、`recent_posts` 等は返さない。

### 2.2 Book

```json
{
  "id": 55,
  "title": "リーダブルコード",
  "author": "Dustin Boswell",
  "isbn": "9784873115658",
  "cover_url": "https://cdn.example.com/books/55.webp",
  "published_on": "2012-06-23",
  "counts": { "likes": 312, "posts": 84 },
  "is_liked": false
}
```

### 2.3 Post

```json
{
  "id": 9821,
  "user": { /* User（短縮形） */ },
  "book": { /* Book（短縮形） nullable */ },
  "body": "とても面白かった。特に第3章...",
  "hashtags": ["読了", "技術書"],
  "counts": { "likes": 12, "comments": 3, "reposts": 1 },
  "is_liked": false,
  "is_reposted": false,
  "created_at": "2026-05-09T10:00:00+09:00",
  "updated_at": "2026-05-09T10:00:00+09:00"
}
```

### 2.4 Comment

```json
{
  "id": 4421,
  "post_id": 9821,
  "user": { /* User（短縮形） */ },
  "body": "私も読みました！",
  "counts": { "likes": 2 },
  "is_liked": false,
  "created_at": "2026-05-09T11:00:00+09:00"
}
```

### 2.5 Repost

```json
{
  "id": 7710,
  "type": "QUOTE",                // SIMPLE or QUOTE
  "user": { /* User */ },
  "post": { /* Post */ },         // 元投稿
  "comment": "これは必読",         // QUOTE 時のみ
  "created_at": "2026-05-09T12:00:00+09:00"
}
```

### 2.6 Notification

```json
{
  "id": 33012,
  "type": "LIKE_POST",
  "actor": { /* User */ },        // 集約時は actors[] になることもある
  "actors_count": 1,
  "target": {
    "type": "Post",
    "id": 9821,
    "preview": "とても面白かった..."
  },
  "read_at": null,
  "created_at": "2026-05-09T10:05:00+09:00"
}
```

---

## 3. 認証・アカウント

### 3.1 サインアップ

`POST /api/v1/auth/signup`

```json
// Request
{
  "email": "user@example.com",
  "password": "SuperSecret123",
  "handle": "yusaku_t",
  "display_name": "津口雄作"
}
```
```json
// 201 Created
{
  "data": {
    "user": { /* User */ },
    "token": "eyJhbGciOi..."
  }
}
```

### 3.2 ログイン

`POST /api/v1/auth/login`

```json
// Request
{ "email": "user@example.com", "password": "SuperSecret123" }
```
```json
// 200 OK
{ "data": { "user": { /* User */ }, "token": "..." } }
```

### 3.3 ログアウト

`DELETE /api/v1/auth/logout` — JWT を Denylist に追加。`204 No Content`。

### 3.4 自分自身

`GET /api/v1/me` — 認証中ユーザー詳細

`PATCH /api/v1/me` — 基本情報更新（後述プロフィール参照）

`DELETE /api/v1/me` — アカウント削除（論理削除）

---

## 4. プロフィール / ユーザー

### 4.1 ユーザー詳細

`GET /api/v1/users/:handle`

- 公開ユーザーは誰でも取得可
- 非公開ユーザーは非フォロワーには `User` 概要のみ返す（投稿一覧は別 API で 403）

### 4.2 プロフィール更新

`PATCH /api/v1/me`

```json
{
  "display_name": "津口雄作",
  "bio": "技術書多めです",
  "is_private": false,
  "reading_goal": 50,
  "favorite_genre_ids": [1, 4, 7],
  "favorite_book_ids": [55, 124, 230]
}
```
- `200 OK` で更新後 `User` を返す

### 4.3 アイコン画像アップロード

`POST /api/v1/me/avatar` — `multipart/form-data` で `file` 添付  
`DELETE /api/v1/me/avatar` — デフォルトに戻す

### 4.4 ハンドル変更

`PATCH /api/v1/me/handle`

```json
{ "handle": "new_handle" }
```
重複時 `409 CONFLICT`、形式不正は `422`。

### 4.5 ユーザー投稿一覧

`GET /api/v1/users/:handle/posts?cursor=&limit=20`

- 非公開アカウントは非フォロワーに対し `403`

### 4.6 フォロワー / フォロイー一覧

| メソッド | パス | 説明 |
|---|---|---|
| GET | `/api/v1/users/:handle/followers?cursor=&limit=` | フォロワー一覧 |
| GET | `/api/v1/users/:handle/following?cursor=&limit=` | フォロイー一覧 |

非公開アカウントはフォロワー以外には `403`。

---

## 5. いいね機能

要件 LK-01〜LK-08 対応。

### 5.1 いいね（付与・解除）

| メソッド | パス | 内容 |
|---|---|---|
| POST | `/api/v1/posts/:id/like` | 投稿にいいね |
| DELETE | `/api/v1/posts/:id/like` | 投稿のいいね解除 |
| POST | `/api/v1/comments/:id/like` | コメントにいいね |
| DELETE | `/api/v1/comments/:id/like` | コメントのいいね解除 |
| POST | `/api/v1/books/:id/like` | 本にいいね |
| DELETE | `/api/v1/books/:id/like` | 本のいいね解除 |

#### レスポンス例（200）
```json
{
  "data": {
    "is_liked": true,
    "likes_count": 13
  }
}
```

#### エラー
- 既にいいね済み・既に解除済み → 冪等に `200`（DB UNIQUE で重複は無視）
- ブロック関係 → `404`
- 自分自身の対象でも 200（要件で禁止していない）

### 5.2 「いいね」リスト取得

要件 LK-04: 件数のみ公開。一覧は限定的。

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/me/likes?type=post|comment|book&cursor=&limit=` | 自分が押したいいね（LK-05） |
| GET | `/api/v1/posts/:id/likes` | **投稿者本人** のみ取得可。他者は `403`。LK-06 |
| GET | `/api/v1/comments/:id/likes` | **コメント本人** のみ取得可（同上） |

`GET /api/v1/books/:id/likes` は提供しない（オーナー不在のため）。

---

## 6. フォロー機能

### 6.1 フォロー（公開：即時、非公開：リクエスト）

`POST /api/v1/users/:handle/follow`

- 公開アカウント: `Follow.status = ACCEPTED` で作成 → 通知発火（FL-N-01）
- 非公開アカウント: `Follow.status = PENDING` で作成 → 通知発火（FL-N-02）

```json
// 201 Created
{
  "data": {
    "status": "PENDING",          // または ACCEPTED
    "user": { /* User（is_following / follow_status 反映済） */ }
  }
}
```

#### エラー
- 自分自身 → `422`
- ブロック関係 → `404`
- 既にフォロー中 → `409`

### 6.2 フォロー解除

`DELETE /api/v1/users/:handle/follow` — `204 No Content`

### 6.3 フォローリクエスト管理（非公開アカウント所有者）

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/me/follow_requests?cursor=&limit=` | 自分への保留中リクエスト一覧 |
| POST | `/api/v1/me/follow_requests/:user_handle/accept` | 承認 → 通知発火（FL-N-03） |
| POST | `/api/v1/me/follow_requests/:user_handle/reject` | 拒否（通知なし） |

### 6.4 ブロック機能

| メソッド | パス | 内容 |
|---|---|---|
| POST | `/api/v1/users/:handle/block` | ブロック → 双方フォロー解除（BL-02、Sidekiq 経由） |
| DELETE | `/api/v1/users/:handle/block` | ブロック解除 |
| GET | `/api/v1/me/blocks?cursor=&limit=` | 自分のブロック一覧（BL-04） |

### 6.5 ミュート機能

| メソッド | パス | 内容 |
|---|---|---|
| POST | `/api/v1/users/:handle/mute` | ミュート（フォロー関係維持、通知なし） |
| DELETE | `/api/v1/users/:handle/mute` | ミュート解除 |
| GET | `/api/v1/me/mutes?cursor=&limit=` | 自分のミュート一覧 |

---

## 7. 投稿・コメント

### 7.1 投稿

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/posts/:id` | 投稿詳細 |
| POST | `/api/v1/posts` | 投稿作成 |
| PATCH | `/api/v1/posts/:id` | 投稿編集（投稿者のみ） |
| DELETE | `/api/v1/posts/:id` | 投稿削除（論理削除、投稿者のみ） |

#### POST /api/v1/posts
```json
{
  "body": "今日は『リーダブルコード』を読んだ #技術書",
  "book_id": 55                   // 任意
}
```
- ハッシュタグは本文中の `#xxx` を抽出して `Hashtag` / `PostHashtag` を自動作成

### 7.2 コメント

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/posts/:id/comments?cursor=&limit=` | コメント一覧 |
| POST | `/api/v1/posts/:id/comments` | コメント作成 |
| PATCH | `/api/v1/comments/:id` | コメント編集（本人のみ） |
| DELETE | `/api/v1/comments/:id` | コメント削除（論理削除、本人または投稿者） |

---

## 8. リポスト機能

### 8.1 単純リポスト（トグル）

`POST /api/v1/posts/:id/repost` — `type=SIMPLE`、再実行で取消（RP-03）

```json
// 201 Created
{
  "data": {
    "is_reposted": true,
    "reposts_count": 14
  }
}
```

`DELETE /api/v1/posts/:id/repost` — 単純リポスト取消（明示）

### 8.2 引用リポスト

`POST /api/v1/posts/:id/quote_repost`

```json
{ "comment": "これは必読" }
```
返却: `Repost` リソース（`type=QUOTE`）

引用リポストの取消は **投稿削除と同等扱い**:  
`DELETE /api/v1/reposts/:id`（本人のみ）

### 8.3 リポスト一覧

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/posts/:id/reposts?cursor=&limit=` | 元投稿に対するリポスト一覧（RP-05） |

### 8.4 制約

- 非公開アカウントの投稿 → `403`（RP-08）
- ブロック関係の投稿 → `404`（RP-09）
- 削除済み元投稿への新規リポスト → `404`

---

## 9. 検索機能

### 9.1 統合検索

`GET /api/v1/search?q=:query&type=:type&page=&per_page=`

- `type` = `users` / `books` / `posts` / `tags` / `all`（default: `all`）
- AND 検索: 半角スペース区切りで複数キーワード
- 非公開アカウント・ブロック関係は SR-04, SR-05 に従いフィルタ

```json
// 200 OK
{
  "data": {
    "users":  [ /* User */ ],
    "books":  [ /* Book */ ],
    "posts":  [ /* Post */ ],
    "tags":   [ /* Hashtag */ ]
  },
  "meta": { /* 各リソースのページ情報 */ }
}
```

`type` 指定時は配列のみを返す:
```json
{ "data": [ /* Post */ ], "meta": { "page": 1, "total": 53 } }
```

### 9.2 サジェスト（オートコンプリート）

`GET /api/v1/search/suggest?q=:prefix&type=users|books|tags&limit=10`

軽量なレスポンス（id, label, optional avatar/cover）を返す。

### 9.3 検索履歴

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/me/search_histories?limit=20` | 自分の検索履歴 |
| DELETE | `/api/v1/me/search_histories/:id` | 個別削除 |
| DELETE | `/api/v1/me/search_histories` | 全削除 |

### 9.4 ハッシュタグ詳細

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/hashtags/:name` | タグ詳細＋件数 |
| GET | `/api/v1/hashtags/:name/posts?cursor=&limit=` | タグ付き投稿一覧（SR-08） |

### 9.5 ジャンル

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/genres` | ジャンル一覧（マスタ） |
| GET | `/api/v1/genres/:id/books?cursor=&limit=` | ジャンルに属する本 |

---

## 10. タイムライン

### 10.1 ホームタイムライン

`GET /api/v1/timeline/home?cursor=&limit=20`

- フォロー中ユーザーの投稿・リポストを時系列降順で返却
- ミュートユーザー除外（MU-02）
- ブロック関係除外
- レスポンスは `Post` または `Repost`（混在のため `kind` で識別）

```json
{
  "data": [
    {
      "kind": "post",
      "post": { /* Post */ }
    },
    {
      "kind": "repost",
      "repost": { /* Repost */ }
    }
  ],
  "meta": { "next_cursor": "...", "has_more": true }
}
```

### 10.2 探索タイムライン（公開全体）

`GET /api/v1/timeline/explore?cursor=&limit=20`

- 公開アカウントの新着投稿を時系列降順で返却（任意機能）

---

## 11. 通知

### 11.1 通知一覧

`GET /api/v1/notifications?cursor=&limit=20&unread_only=false`

- 自分宛通知を時系列降順
- 集約済みの通知（LK-N-03）は `actors_count` と `actors[]`（先頭数件）で表現

### 11.2 既読化

| メソッド | パス | 内容 |
|---|---|---|
| POST | `/api/v1/notifications/:id/read` | 個別既読化 |
| POST | `/api/v1/notifications/read_all` | 一括既読化 |
| GET | `/api/v1/notifications/unread_count` | 未読件数（ベルバッジ用） |

---

## 12. 本（書籍マスタ）

### 12.1 本検索／取得

| メソッド | パス | 内容 |
|---|---|---|
| GET | `/api/v1/books/:id` | 本詳細＋件数（counts.likes, counts.posts） |
| GET | `/api/v1/books/:id/posts?cursor=&limit=` | この本に紐づく投稿一覧 |
| GET | `/api/v1/books?q=&isbn=&cursor=&limit=` | 検索（タイトル / 著者 / ISBN） |

### 12.2 本の登録（ISBN 検索の延長で）

`POST /api/v1/books`

外部 API（OpenBD / Google Books）からインポートしたメタを保存（ログインユーザーなら誰でも実行可、UNIQUE ISBN で重複防止）。

```json
{
  "isbn": "9784873115658",
  "title": "リーダブルコード",
  "author": "Dustin Boswell",
  "cover_url": "https://...",
  "published_on": "2012-06-23"
}
```

---

## 13. デバイス（プッシュ通知用）

### 13.1 デバイストークン登録

`POST /api/v1/me/devices`

```json
{ "platform": "web", "token": "BNc..." }
```

### 13.2 削除

`DELETE /api/v1/me/devices/:id`

---

## 14. 公開設定切り替え

`PATCH /api/v1/me/privacy`

```json
{ "is_private": true }
```

要件 PR-04 即時反映。  
公開→非公開: 既存フォロワー維持、新規はリクエスト制（FL-03）  
非公開→公開: 保留中リクエストは自動承認しない（FL-04）

---

## 15. 主要ユースケースのシーケンス

### 15.1 投稿にいいね（公開アカウント）

```
Client -> POST /api/v1/posts/9821/like
  Rails: Like 作成（UNIQUE 競合は無視）
       → Sidekiq: LikeNotificationWorker
                  → Notification 作成
                  → FCM / Web Push 送信
  -> 200 { is_liked: true, likes_count: 13 }
```

### 15.2 非公開アカウントへのフォロー → 承認

```
Client(A) -> POST /api/v1/users/B/follow
  Rails: Follow(status=PENDING) 作成
       → Sidekiq: 通知（FOLLOW_REQUEST）
  -> 201 { status: "PENDING" }

Client(B) -> POST /api/v1/me/follow_requests/A/accept
  Rails: Follow.status = ACCEPTED
       → Sidekiq: 通知（FOLLOW_ACCEPTED）to A
  -> 200
```

### 15.3 ブロック → 関係クリーンアップ

```
Client(A) -> POST /api/v1/users/B/block
  Rails: Block 作成
       → Sidekiq: BlockCleanupWorker
                  → Follow(双方向) 削除
                  → Like(A→B 投稿)・Repost 等の整合性整理
  -> 201
```

---

## 16. ルーティング全体図（Rails）

```ruby
# config/routes.rb（抜粋）
namespace :api do
  namespace :v1 do
    # 認証
    post   'auth/signup', to: 'auth#signup'
    post   'auth/login',  to: 'auth#login'
    delete 'auth/logout', to: 'auth#logout'

    # 自分
    resource :me, only: [:show, :update, :destroy] do
      resource :avatar,   only: [:create, :destroy]
      resource :handle,   only: [:update]
      resource :privacy,  only: [:update]
      resources :likes, only: [:index]
      resources :follow_requests, only: [:index] do
        post :accept, on: :member
        post :reject, on: :member
      end
      resources :blocks, only: [:index]
      resources :mutes,  only: [:index]
      resources :search_histories, only: [:index, :destroy] do
        delete :index, on: :collection, action: :destroy_all
      end
      resources :devices, only: [:create, :destroy]
    end

    # ユーザー
    resources :users, param: :handle, only: [:show] do
      resources :posts, only: [:index]
      member do
        get  :followers
        get  :following
        post   'follow', to: 'follows#create'
        delete 'follow', to: 'follows#destroy'
        post   'block',  to: 'blocks#create'
        delete 'block',  to: 'blocks#destroy'
        post   'mute',   to: 'mutes#create'
        delete 'mute',   to: 'mutes#destroy'
      end
    end

    # 投稿
    resources :posts, only: [:show, :create, :update, :destroy] do
      resources :comments, only: [:index, :create]
      member do
        post   'like',         to: 'likes#create_for_post'
        delete 'like',         to: 'likes#destroy_for_post'
        post   'repost',       to: 'reposts#create_simple'
        delete 'repost',       to: 'reposts#destroy_simple'
        post   'quote_repost', to: 'reposts#create_quote'
        get    'reposts',      to: 'reposts#index'
        get    'likes',        to: 'likes#index_for_post'
      end
    end

    # コメント
    resources :comments, only: [:update, :destroy] do
      member do
        post   'like', to: 'likes#create_for_comment'
        delete 'like', to: 'likes#destroy_for_comment'
        get    'likes', to: 'likes#index_for_comment'
      end
    end

    # 引用リポストの単独削除
    resources :reposts, only: [:destroy]

    # 本
    resources :books, only: [:index, :show, :create] do
      resources :posts, only: [:index]
      member do
        post   'like', to: 'likes#create_for_book'
        delete 'like', to: 'likes#destroy_for_book'
      end
    end

    # ハッシュタグ・ジャンル
    resources :hashtags, param: :name, only: [:show] do
      resources :posts, only: [:index]
    end
    resources :genres, only: [:index] do
      resources :books, only: [:index]
    end

    # 検索
    get 'search',         to: 'search#index'
    get 'search/suggest', to: 'search#suggest'

    # タイムライン
    get 'timeline/home',    to: 'timeline#home'
    get 'timeline/explore', to: 'timeline#explore'

    # 通知
    resources :notifications, only: [:index] do
      member do
        post 'read', to: 'notifications#read'
      end
      collection do
        post 'read_all',     to: 'notifications#read_all'
        get  'unread_count', to: 'notifications#unread_count'
      end
    end
  end
end
```

---

## 17. OpenAPI / ドキュメント生成

- バックエンドは **rswag** で `spec/integration/` に書き、`/api-docs` で Swagger UI を自動公開
- Next.js 側は `openapi-typescript` で型定義を自動生成（CI で同期）

```bash
# 生成例
docker compose exec backend bundle exec rake rswag:specs:swaggerize
docker compose exec frontend pnpm openapi-typescript ../backend/swagger/v1/swagger.yaml -o lib/api/types.ts
```

---

## 18. セキュリティ・運用上の注意

| 項目 | 方針 |
|---|---|
| CORS | `rack-cors` で Next.js のオリジンのみ許可。Cookie 利用時は `credentials: true` |
| CSRF | Cookie 利用時は SameSite=Lax + Origin チェックで対応。Bearer のみなら不要 |
| パスワード | Devise の bcrypt（既定）、強度ポリシーは Validator で |
| JWT 失効 | `jti` Denylist 戦略、ログアウト時は確実に失効 |
| レート制限 | `rack-attack` を導入、IP / ユーザー単位で制限 |
| 入力サニタイズ | 投稿本文は HTML をエスケープ、表示時にサーバ側で安全化 |
| Mass Assignment | Strong Parameters を厳守 |
| 機微情報ログ抑止 | Rails `filter_parameters` に `password`, `token` を登録 |

---

## 19. 範囲外（次フェーズ）

- WebSocket（Action Cable）によるリアルタイム通知
- GraphQL ゲートウェイ
- 通報・モデレーション API
- DM API
- 推薦 API（フォロー推薦・本推薦）
