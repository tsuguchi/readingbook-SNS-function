module Api
  module V1
    module Timeline
      # GET /api/v1/timeline/explore
      # 公開アカウントの新着投稿（ブロック関係除外）
      class ExploreController < Api::V1::BaseController
        def index
          posts = TimelineService.new(user: current_user).explore(limit: limit, offset: offset)

          render json: PostSerializer.new(posts, params: { current_user: current_user }).serializable_hash,
                 status: :ok
        end

        private

        def limit
          params.fetch(:limit, 20).to_i
        end

        def offset
          [ params.fetch(:offset, 0).to_i, 0 ].max
        end
      end
    end
  end
end
