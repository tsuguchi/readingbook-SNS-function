module Api
  module V1
    # GET /api/v1/hashtags/:name  タグ詳細（投稿件数）
    class HashtagsController < BaseController
      def show
        tag = Hashtag.find_by!(name: params[:name])
        render json: HashtagSerializer.new(tag).serializable_hash, status: :ok
      end
    end
  end
end
