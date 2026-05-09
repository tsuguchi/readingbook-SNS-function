module Api
  module V1
    # GET /api/v1/me  …… ログイン中ユーザー自身の情報
    class MeController < BaseController
      def show
        render json: UserSerializer.new(current_user).serializable_hash, status: :ok
      end
    end
  end
end
