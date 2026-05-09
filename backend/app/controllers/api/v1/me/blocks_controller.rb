module Api
  module V1
    module Me
      # GET /api/v1/me/blocks
      # 自分がブロックしているユーザー一覧（要件 BL-04）
      class BlocksController < Api::V1::BaseController
        def index
          users = User.joins("INNER JOIN blocks ON blocks.blocked_id = users.id")
                      .where(blocks: { blocker_id: current_user.id })
                      .order("blocks.created_at DESC")

          render json: UserSerializer.new(users).serializable_hash, status: :ok
        end
      end
    end
  end
end
