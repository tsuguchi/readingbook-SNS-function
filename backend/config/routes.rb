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
    end
  end

  # Devise デフォルトルーティングを無効化（Devise の view ベースを使わないため）
  devise_for :users, skip: :all
end
