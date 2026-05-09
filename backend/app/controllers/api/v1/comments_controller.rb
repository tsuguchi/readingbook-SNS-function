module Api
  module V1
    # 投稿に対するコメント。一覧 / 作成 / 編集 / 削除。
    class CommentsController < BaseController
      before_action :set_post, only: %i[index create]
      before_action :set_comment, only: %i[update destroy]
      before_action :authorize_comment_owner!, only: %i[update destroy]

      # GET /api/v1/posts/:post_id/comments
      def index
        comments = @post.comments.alive.includes(:user).order(:created_at)

        render json: CommentSerializer.new(comments, serializer_options).serializable_hash, status: :ok
      end

      # POST /api/v1/posts/:post_id/comments
      def create
        comment = @post.comments.new(comment_params.merge(user: current_user))
        comment.save!

        render json: CommentSerializer.new(comment, serializer_options).serializable_hash, status: :created
      end

      # PATCH /api/v1/comments/:id
      def update
        @comment.update!(comment_params)
        render json: CommentSerializer.new(@comment, serializer_options).serializable_hash, status: :ok
      end

      # DELETE /api/v1/comments/:id
      def destroy
        @comment.update!(deleted_at: Time.current)
        head :no_content
      end

      private

      def set_post
        @post = Post.alive.find(params[:post_id])
      end

      def set_comment
        @comment = Comment.alive.find(params[:id])
      end

      def authorize_comment_owner!
        return if @comment.user_id == current_user.id
        # 投稿者は自分の投稿に付いたコメントを削除できる仕様
        return if action_name == "destroy" && @comment.post.user_id == current_user.id

        render_error(:forbidden, "このコメントは編集・削除できません", status: :forbidden)
      end

      def comment_params
        params.require(:comment).permit(:body)
      end

      def serializer_options
        { params: { current_user: current_user } }
      end
    end
  end
end
