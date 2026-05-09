module Api
  module V1
    module Users
      # POST   /api/v1/users/:user_handle/mute   ミュート
      # DELETE /api/v1/users/:user_handle/mute   ミュート解除
      class MutesController < Api::V1::BaseController
        before_action :find_target_user

        def create
          MuteService.mute!(muter: current_user, muted: @target_user)
          head :created
        rescue MuteService::CannotMuteSelf
          render_error(:validation_failed, "自分自身をミュートすることはできません",
                       status: :unprocessable_entity)
        end

        def destroy
          MuteService.unmute!(muter: current_user, muted: @target_user)
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
