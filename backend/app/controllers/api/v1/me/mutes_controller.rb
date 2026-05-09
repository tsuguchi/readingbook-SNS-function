module Api
  module V1
    module Me
      # GET /api/v1/me/mutes
      # 自分がミュートしているユーザー一覧
      class MutesController < Api::V1::BaseController
        def index
          users = User.joins("INNER JOIN mutes ON mutes.muted_id = users.id")
                      .where(mutes: { muter_id: current_user.id })
                      .order("mutes.created_at DESC")

          render json: UserSerializer.new(users).serializable_hash, status: :ok
        end
      end
    end
  end
end
