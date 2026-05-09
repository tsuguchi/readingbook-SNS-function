module Api
  module V1
    module Me
      # GET /api/v1/me/likes
      # 自分が押したいいねの一覧（要件 LK-05）
      # クエリパラメータ:
      #   type=post|comment|book で対象種別を絞り込み（省略時は全種別）
      class LikesController < Api::V1::BaseController
        TYPE_MAP = {
          "post" => "Post",
          "comment" => "Comment",
          "book" => "Book"
        }.freeze

        def index
          scope = current_user.likes.order(created_at: :desc)
          scope = scope.where(target_type: TYPE_MAP[params[:type]]) if TYPE_MAP.key?(params[:type])

          # N+1 を避けるためポリモーフィック先を eager load
          likes = scope.includes(:target).limit(limit).offset(offset)

          render json: LikeSerializer.new(likes, params: { current_user: current_user }).serializable_hash,
                 status: :ok
        end

        private

        def limit
          [ params.fetch(:limit, 20).to_i, 100 ].min
        end

        def offset
          [ params.fetch(:offset, 0).to_i, 0 ].max
        end
      end
    end
  end
end
