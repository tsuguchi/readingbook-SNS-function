module Api
  module V1
    module Me
      # GET    /api/v1/me/search_histories          自分の検索履歴
      # DELETE /api/v1/me/search_histories/:id      個別削除
      # DELETE /api/v1/me/search_histories          一括削除
      class SearchHistoriesController < Api::V1::BaseController
        def index
          histories = current_user.search_histories
                                  .order(executed_at: :desc)
                                  .limit(limit)

          data = histories.map do |h|
            { id: h.id.to_s, query: h.query, category: h.category,
              executed_at: h.executed_at }
          end

          render json: { data: data }, status: :ok
        end

        def destroy
          current_user.search_histories.find(params[:id]).destroy!
          head :no_content
        end

        def destroy_all
          current_user.search_histories.destroy_all
          head :no_content
        end

        private

        def limit
          [ params.fetch(:limit, 30).to_i, 100 ].min
        end
      end
    end
  end
end
