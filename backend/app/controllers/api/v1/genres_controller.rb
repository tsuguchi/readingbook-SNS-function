module Api
  module V1
    # GET /api/v1/genres
    # ジャンルマスタ一覧（読書プロフィールのジャンル選択候補）
    class GenresController < BaseController
      def index
        render json: { data: Genre.order(:name).pluck(:id, :name).map { |id, name| { id: id.to_s, name: name } } },
               status: :ok
      end
    end
  end
end
