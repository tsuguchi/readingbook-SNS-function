module Api
  module V1
    module Posts
      # POST   /api/v1/posts/:post_id/repost         単純リポスト（トグル）
      # DELETE /api/v1/posts/:post_id/repost         単純リポスト解除
      # POST   /api/v1/posts/:post_id/quote_repost   引用リポスト作成
      # GET    /api/v1/posts/:post_id/reposts        リポスト一覧（要件 RP-05）
      class RepostsController < Api::V1::BaseController
        before_action :find_post

        # 単純リポスト（トグル：既存があれば取消、無ければ作成）
        def create
          result = RepostService.toggle_simple!(user: current_user, post: @post)

          render json: {
            data: {
              is_reposted: result[:action] == :created,
              reposts_count: RepostService.count_for(@post)
            }
          }, status: :ok
        rescue RepostService::RepostForbidden
          render_error(:not_found, "リソースが見つかりません", status: :not_found)
        end

        # 単純リポストの明示的解除（冪等）
        def destroy
          RepostService.destroy_simple!(user: current_user, post: @post)

          render json: {
            data: {
              is_reposted: false,
              reposts_count: RepostService.count_for(@post)
            }
          }, status: :ok
        end

        # 引用リポスト作成
        def create_quote
          repost = RepostService.create_quote!(
            user: current_user,
            post: @post,
            comment: params.dig(:repost, :comment)
          )

          render json: RepostSerializer.new(repost, params: { current_user: current_user }).serializable_hash,
                 status: :created
        rescue RepostService::CommentRequired
          render_error(:validation_failed, "コメントは必須です",
                       status: :unprocessable_entity,
                       details: [ { field: :comment, message: "を入力してください" } ])
        rescue RepostService::RepostForbidden
          render_error(:not_found, "リソースが見つかりません", status: :not_found)
        end

        # 元投稿に対するリポスト一覧（単純 + 引用、新着順）
        def index
          reposts = Repost.where(post: @post)
                          .includes(:user, post: %i[user book hashtags])
                          .order(created_at: :desc)
                          .limit(limit)
                          .offset(offset)

          render json: RepostSerializer.new(reposts, params: { current_user: current_user }).serializable_hash,
                 status: :ok
        end

        private

        def find_post
          @post = Post.alive.find(params[:post_id])
        end

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
