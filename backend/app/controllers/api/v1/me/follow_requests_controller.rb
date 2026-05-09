module Api
  module V1
    module Me
      # GET  /api/v1/me/follow_requests                       自分宛の保留中リクエスト一覧
      # POST /api/v1/me/follow_requests/:user_handle/accept  承認 → status=accepted + 通知
      # POST /api/v1/me/follow_requests/:user_handle/reject  拒否 → Follow を削除（通知なし）
      class FollowRequestsController < Api::V1::BaseController
        before_action :find_follow, only: %i[accept reject]

        def index
          follows = Follow.where(followee: current_user, status: "pending")
                          .includes(:follower)
                          .order(created_at: :desc)
          users = follows.map(&:follower)

          render json: UserSerializer.new(users).serializable_hash, status: :ok
        end

        def accept
          FollowService.accept!(@follow)
          head :no_content
        end

        def reject
          FollowService.reject!(@follow)
          head :no_content
        end

        private

        def find_follow
          follower = User.find_by!(handle: params[:user_handle])
          @follow = Follow.find_by!(follower: follower, followee: current_user, status: "pending")
        end
      end
    end
  end
end
