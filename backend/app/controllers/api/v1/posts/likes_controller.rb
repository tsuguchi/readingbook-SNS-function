module Api
  module V1
    module Posts
      # POST   /api/v1/posts/:post_id/like   いいね（トグル）
      # DELETE /api/v1/posts/:post_id/like   いいね解除（冪等）
      # GET    /api/v1/posts/:post_id/likes  いいねしたユーザー一覧（投稿者本人のみ：要件 LK-06）
      class LikesController < Api::V1::BaseController
        include LikeAction

        # GET /api/v1/posts/:post_id/likes
        def index
          # 要件 LK-06：投稿者本人のみ閲覧可
          unless @target.user_id == current_user.id
            return render_error(:forbidden, "いいねしたユーザーは公開されていません",
                                status: :forbidden)
          end

          users = User.joins(:likes)
                      .where(likes: { target_type: "Post", target_id: @target.id })
                      .order("likes.created_at DESC")

          render json: UserSerializer.new(users).serializable_hash, status: :ok
        end

        private

        def find_target
          @target = Post.alive.find(params[:post_id])
        end
      end
    end
  end
end
