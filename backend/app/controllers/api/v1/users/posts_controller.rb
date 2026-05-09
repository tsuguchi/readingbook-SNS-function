module Api
  module V1
    module Users
      # GET /api/v1/users/:user_handle/posts
      # 対象ユーザーの投稿一覧。非公開アカウントはフォロワー以外には 403。
      class PostsController < Api::V1::BaseController
        def index
          target = User.find_by!(handle: params[:user_handle])

          if private_and_not_visible?(target)
            return render_error(:forbidden, "このユーザーの投稿は閲覧できません",
                                status: :forbidden)
          end

          posts = target.posts
                        .alive
                        .includes(:user, :book, :hashtags)
                        .order(created_at: :desc)
                        .limit(limit)
                        .offset(offset)

          render json: PostSerializer.new(posts, params: { current_user: current_user }).serializable_hash,
                 status: :ok
        end

        private

        def private_and_not_visible?(target)
          return false unless target.is_private?
          return false if target == current_user
          return false if Follow.exists?(follower: current_user, followee: target, status: "accepted")

          true
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
