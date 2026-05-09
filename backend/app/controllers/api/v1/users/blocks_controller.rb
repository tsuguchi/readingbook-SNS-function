module Api
  module V1
    module Users
      # POST   /api/v1/users/:user_handle/block   ブロック
      # DELETE /api/v1/users/:user_handle/block   ブロック解除（冪等）
      class BlocksController < Api::V1::BaseController
        before_action :find_target_user

        def create
          BlockService.block!(blocker: current_user, blocked: @target_user)
          head :created
        rescue BlockService::CannotBlockSelf
          render_error(:validation_failed, "自分自身をブロックすることはできません",
                       status: :unprocessable_entity)
        end

        def destroy
          BlockService.unblock!(blocker: current_user, blocked: @target_user)
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
