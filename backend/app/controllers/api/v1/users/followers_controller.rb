module Api
  module V1
    module Users
      # GET /api/v1/users/:user_handle/followers
      # フォロワー一覧（要件 FL-06）
      # 非公開アカウントの場合、フォロワー以外には 403 を返す。
      class FollowersController < Api::V1::BaseController
        def index
          target = User.find_by!(handle: params[:user_handle])

          if private_and_not_visible?(target)
            return render_error(:forbidden, "このユーザーのフォロワーは公開されていません",
                                status: :forbidden)
          end

          users = User.joins("INNER JOIN follows ON follows.follower_id = users.id")
                      .where(follows: { followee_id: target.id, status: "accepted" })
                      .order("follows.created_at DESC")

          render json: UserSerializer.new(users).serializable_hash, status: :ok
        end

        private

        def private_and_not_visible?(target)
          return false unless target.is_private?
          return false if target == current_user
          return false if Follow.exists?(follower: current_user, followee: target, status: "accepted")

          true
        end
      end
    end
  end
end
