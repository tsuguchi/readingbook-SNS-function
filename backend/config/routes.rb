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

      # 投稿
      resources :posts, only: %i[show create update destroy] do
        # 投稿に紐づくコメント（一覧・作成）
        resources :comments, only: %i[index create]
      end

      # コメント単独操作（編集・削除）
      resources :comments, only: %i[update destroy]
    end
  end

  # Devise デフォルトルーティングを無効化（Devise の view ベースを使わないため）
  devise_for :users, skip: :all
end
