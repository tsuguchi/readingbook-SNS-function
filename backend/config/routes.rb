Rails.application.routes.draw do
  # ヘルスチェック（ALB / 監視向け）
  get "up" => "rails/health#show", as: :rails_health_check

  # API v1
  namespace :api do
    namespace :v1 do
      # 認証エンドポイント。Devise のルーティングは API モードでは使わず、
      # 自前の Auth::SessionsController / Auth::RegistrationsController に集約する。
      post   "auth/signup", to: "auth/registrations#create"
      post   "auth/login",  to: "auth/sessions#create"
      delete "auth/logout", to: "auth/sessions#destroy"

      # 認証済みユーザー自身の情報（取得・プロフィール更新）
      resource :me, only: %i[show update], controller: "me"

      # タイムライン
      get "timeline/home",    to: "timeline/home#index"
      get "timeline/explore", to: "timeline/explore#index"

      # 通知（要件 LK-N / FL-N / RP-N）
      resources :notifications, only: [ :index ] do
        member do
          post :read
        end
        collection do
          post :read_all
          get  :unread_count
        end
      end
      # /api/v1/me 配下の各種一覧・管理
      namespace :me do
        resources :likes, only: [ :index ]
        resources :blocks, only: [ :index ]
        resources :mutes, only: [ :index ]
        # 自分宛のフォローリクエスト：accept / reject はメンバーアクション
        resources :follow_requests, only: [ :index ], param: :user_handle do
          member do
            post :accept
            post :reject
          end
        end
      end

      # ユーザープロフィール詳細
      resources :users, only: [ :show ], param: :handle do
        # 投稿一覧
        resources :posts, only: [ :index ], controller: "users/posts"
        # フォロー / ブロック / ミュート / フォロワー・フォロイー一覧
        resource :follow, only: %i[create destroy], controller: "users/follows"
        resource :block,  only: %i[create destroy], controller: "users/blocks"
        resource :mute,   only: %i[create destroy], controller: "users/mutes"
        resources :followers, only: [ :index ], controller: "users/followers"
        resources :following, only: [ :index ], controller: "users/following"
      end

      # 投稿
      resources :posts, only: %i[show create update destroy] do
        # 投稿に紐づくコメント（一覧・作成）
        resources :comments, only: %i[index create]
        # いいね（トグル）／いいねしたユーザー一覧（要件 LK-06）
        resource  :like, only: %i[create destroy], controller: "posts/likes"
        resources :likes, only: [ :index ], controller: "posts/likes"
        # リポスト（要件 RP-01〜RP-09）
        resource  :repost, only: %i[create destroy], controller: "posts/reposts"
        resources :reposts, only: [ :index ], controller: "posts/reposts"
        post "quote_repost", to: "posts/reposts#create_quote"
      end

      # 引用リポストの単独削除（投稿削除と同等扱い）
      resources :reposts, only: [ :destroy ]

      # コメント単独操作（編集・削除）
      resources :comments, only: %i[update destroy] do
        resource  :like, only: %i[create destroy], controller: "comments/likes"
        resources :likes, only: [ :index ], controller: "comments/likes"
      end

      # 書籍マスタ
      resources :books, only: %i[index show create] do
        # この本に紐づく投稿一覧
        resources :posts, only: [ :index ], controller: "books/posts"
        # 本へのいいね（書籍マスタにはオーナーが居ないため index は提供しない）
        resource :like, only: %i[create destroy], controller: "books/likes"
      end

      # ハッシュタグ
      # name にスラッシュ等の特殊文字が入らない前提で param: :name を使う
      resources :hashtags, only: [ :show ], param: :name do
        resources :posts, only: [ :index ], controller: "hashtags/posts"
      end

      # ジャンルマスタ
      resources :genres, only: [ :index ]
    end
  end

  # Devise デフォルトルーティングを無効化（Devise の view ベースを使わないため）
  devise_for :users, skip: :all
end
