module Api
  module V1
    module Auth
      # POST   /api/v1/auth/login   …… JWT 発行
      # DELETE /api/v1/auth/logout  …… JWT 失効（jti 更新）
      class SessionsController < ApplicationController
        before_action :authenticate_user!, only: :destroy

        def create
          user = User.find_for_database_authentication(email: login_params[:email])

          if user&.valid_password?(login_params[:password])
            # warden 経由でログインさせ、devise-jwt の dispatch_requests により
            # Authorization ヘッダに JWT が自動付与される。
            sign_in(user, store: false)
            token = request.env["warden-jwt_auth.token"] || response.headers["Authorization"]&.sub(/^Bearer\s+/, "")

            render json: {
              data: UserSerializer.new(user).serializable_hash[:data],
              meta: { token: token }
            }, status: :ok
          else
            render_error(:unauthenticated, "メールアドレスまたはパスワードが正しくありません",
                         status: :unauthorized)
          end
        end

        def destroy
          # devise-jwt の revocation_requests に該当するため、
          # JTIMatcher 戦略で User#jti が新しい UUID に更新され、
          # 既存トークンはすべて無効化される。
          sign_out(current_user)
          head :no_content
        end

        private

        def login_params
          params.require(:auth).permit(:email, :password)
        end
      end
    end
  end
end
