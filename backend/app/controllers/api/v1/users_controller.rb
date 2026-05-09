module Api
  module V1
    # GET /api/v1/users/:handle
    # ユーザープロフィール詳細。
    # 非公開アカウントもプロフィール自体は表示する（投稿一覧のみ非公開）
    # — Twitter/X 流の挙動。
    class UsersController < Api::V1::BaseController
      def show
        target = User.find_by!(handle: params[:handle])
        render json: UserSerializer.new(target).serializable_hash, status: :ok
      end
    end
  end
end
