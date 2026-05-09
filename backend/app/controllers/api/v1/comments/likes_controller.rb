module Api
  module V1
    module Comments
      # POST   /api/v1/comments/:comment_id/like   いいね
      # DELETE /api/v1/comments/:comment_id/like   いいね解除
      # GET    /api/v1/comments/:comment_id/likes  いいねしたユーザー一覧（コメント本人のみ）
      class LikesController < Api::V1::BaseController
        include LikeAction

        def index
          unless @target.user_id == current_user.id
            return render_error(:forbidden, "いいねしたユーザーは公開されていません",
                                status: :forbidden)
          end

          users = User.joins(:likes)
                      .where(likes: { target_type: "Comment", target_id: @target.id })
                      .order("likes.created_at DESC")

          render json: UserSerializer.new(users).serializable_hash, status: :ok
        end

        private

        def find_target
          @target = Comment.alive.find(params[:comment_id])
        end
      end
    end
  end
end
