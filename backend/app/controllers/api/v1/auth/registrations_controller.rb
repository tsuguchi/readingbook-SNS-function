module Api
  module V1
    module Auth
      # POST /api/v1/auth/signup
      # 新規ユーザー登録 + JWT 発行。
      class RegistrationsController < ApplicationController
        # サインアップは未ログイン状態でアクセスする
        # （ApplicationController に authenticate_user! は付けていないが念のため）

        def create
          user = User.new(signup_params)

          if user.save
            # warden に user を載せると devise-jwt の dispatch_requests により
            # レスポンスの Authorization ヘッダに JWT が自動付与される。
            # store: false でセッションには保存しない（JWT のみで認証するため）。
            sign_in(user, store: false)

            token = response.headers["Authorization"]&.sub(/^Bearer\s+/, "") ||
                    request.env["warden-jwt_auth.token"]

            render json: {
              data: UserSerializer.new(user).serializable_hash[:data],
              meta: { token: token }
            }, status: :created
          else
            render_validation_failed(ActiveRecord::RecordInvalid.new(user))
          end
        end

        private

        def signup_params
          params.require(:auth).permit(:email, :password, :handle, :display_name)
        end

        # warden-jwt_auth はトークンをレスポンスヘッダに書き出すが、
        # 一部バージョンでは env キーで保持している。両対応のフォールバック。
        def extract_token_from_response
          response.headers["Authorization"]&.sub(/^Bearer\s+/, "")
        end
      end
    end
  end
end
