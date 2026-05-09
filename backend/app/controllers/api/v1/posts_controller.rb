module Api
  module V1
    # 投稿（読書感想・レビュー）の CRUD。
    # 認証必須（BaseController から継承）。
    class PostsController < BaseController
      # 詳細・一覧は認証なしでも公開アカウントの投稿は閲覧可能だが、
      # 現フェーズでは認証必須に統一しておく（公開タイムラインは別途実装予定）。
      before_action :set_post, only: %i[show update destroy]
      before_action :authorize_owner!, only: %i[update destroy]

      # GET /api/v1/posts/:id
      def show
        render json: PostSerializer.new(@post, serializer_options).serializable_hash, status: :ok
      end

      # POST /api/v1/posts
      def create
        post = current_user.posts.new(post_params)
        ActiveRecord::Base.transaction do
          post.save!
          HashtagExtractor.sync!(post)
        end

        render json: PostSerializer.new(post, serializer_options).serializable_hash, status: :created
      end

      # PATCH /api/v1/posts/:id
      def update
        ActiveRecord::Base.transaction do
          @post.update!(post_params)
          HashtagExtractor.sync!(@post)
        end

        render json: PostSerializer.new(@post, serializer_options).serializable_hash, status: :ok
      end

      # DELETE /api/v1/posts/:id
      # 論理削除（deleted_at に Time.current を入れる）
      def destroy
        @post.update!(deleted_at: Time.current)
        head :no_content
      end

      private

      def set_post
        @post = Post.alive.find(params[:id])
      end

      def authorize_owner!
        return if @post.user_id == current_user.id

        render_error(:forbidden, "他人の投稿は編集・削除できません", status: :forbidden)
      end

      def post_params
        params.require(:post).permit(:body, :book_id)
      end

      def serializer_options
        { params: { current_user: current_user } }
      end
    end
  end
end
