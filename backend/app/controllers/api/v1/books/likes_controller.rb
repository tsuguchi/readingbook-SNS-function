module Api
  module V1
    module Books
      # POST   /api/v1/books/:book_id/like   いいね
      # DELETE /api/v1/books/:book_id/like   いいね解除
      # 注：本（Book）にはオーナー不在のため index は提供しない（要件 LK-N-05 と整合）
      class LikesController < Api::V1::BaseController
        include LikeAction

        private

        def find_target
          @target = Book.find(params[:book_id])
        end
      end
    end
  end
end
