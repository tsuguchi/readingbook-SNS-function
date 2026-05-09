module Api
  module V1
    # DELETE /api/v1/reposts/:id
    # 引用リポストの単独削除（投稿削除と同等扱い、本人のみ）
    class RepostsController < Api::V1::BaseController
      def destroy
        repost = Repost.find(params[:id])

        unless repost.user_id == current_user.id
          return render_error(:forbidden, "他人のリポストは削除できません", status: :forbidden)
        end

        repost.destroy!
        head :no_content
      end
    end
  end
end
