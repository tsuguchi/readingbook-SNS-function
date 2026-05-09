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

      # 認証済みユーザー自身の情報
      resource :me, only: [ :show ], controller: "me"
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

      # ユーザー操作（フォロー / ブロック / ミュート / フォロワー・フォロイー一覧）
      resources :users, only: [], param: :handle do
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
        # 単数 resource：POST/DELETE /posts/:post_id/like
        resource  :like, only: %i[create destroy], controller: "posts/likes"
        # 複数 resources：GET /posts/:post_id/likes
        resources :likes, only: [ :index ], controller: "posts/likes"
      end

      # コメント単独操作（編集・削除）
      resources :comments, only: %i[update destroy] do
        resource  :like, only: %i[create destroy], controller: "comments/likes"
        resources :likes, only: [ :index ], controller: "comments/likes"
      end

      # 本へのいいね（書籍マスタにはオーナーが居ないため index は提供しない）
      resources :books, only: [] do
        resource :like, only: %i[create destroy], controller: "books/likes"
      end
    end
  end

  # Devise デフォルトルーティングを無効化（Devise の view ベースを使わないため）
  devise_for :users, skip: :all
end
