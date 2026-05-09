module Api
  module V1
    module Hashtags
      # GET /api/v1/hashtags/:hashtag_name/posts
      # 指定ハッシュタグが付いた投稿一覧（公開アカウントのみ、新着順）
      class PostsController < Api::V1::BaseController
        def index
          tag = Hashtag.find_by!(name: params[:hashtag_name])

          posts = Post.alive
                      .joins(:hashtags, :user)
                      .where(hashtags: { id: tag.id })
                      .where(users: { is_private: false })
                      .includes(:user, :book, :hashtags)
                      .order(created_at: :desc)
                      .limit(limit)
                      .offset(offset)

          render json: PostSerializer.new(posts, params: { current_user: current_user }).serializable_hash,
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
