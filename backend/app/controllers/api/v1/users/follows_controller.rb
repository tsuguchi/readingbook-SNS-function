module Api
  module V1
    module Users
      # POST   /api/v1/users/:user_handle/follow   フォロー（公開なら即時、非公開ならリクエスト）
      # DELETE /api/v1/users/:user_handle/follow   フォロー解除（冪等）
      class FollowsController < Api::V1::BaseController
        before_action :find_target_user

        def create
          follow = FollowService.follow!(follower: current_user, followee: @target_user)

          render json: {
            data: {
              status: follow.status,
              user: UserSerializer.new(@target_user).serializable_hash[:data]
            }
          }, status: :created
        rescue FollowService::CannotFollowSelf
          render_error(:validation_failed, "自分自身をフォローすることはできません",
                       status: :unprocessable_entity)
        rescue FollowService::FollowForbidden
          render_error(:not_found, "リソースが見つかりません", status: :not_found)
        end

        def destroy
          FollowService.unfollow!(follower: current_user, followee: @target_user)
          head :no_content
        end

        private

        def find_target_user
          @target_user = User.find_by!(handle: params[:user_handle])
        end
      end
    end
  end
end
