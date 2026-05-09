module Api
  module V1
    # GET   /api/v1/me   ログイン中ユーザーの情報
    # PATCH /api/v1/me   プロフィール更新（display_name / bio / is_private / reading_goal /
    #                    favorite_genre_ids / favorite_book_ids）
    class MeController < BaseController
      def show
        render json: UserSerializer.new(current_user).serializable_hash, status: :ok
      end

      def update
        ActiveRecord::Base.transaction do
          current_user.update!(profile_params)
          sync_genres! if params.dig(:me, :favorite_genre_ids)
          sync_favorite_books! if params.dig(:me, :favorite_book_ids)
        end

        render json: UserSerializer.new(current_user.reload).serializable_hash, status: :ok
      end

      private

      def profile_params
        params.require(:me).permit(:display_name, :bio, :is_private, :reading_goal)
      end

      def sync_genres!
        ids = Array(params.dig(:me, :favorite_genre_ids)).map(&:to_i).uniq
        # 存在するジャンル ID のみ取り扱う
        ids &= Genre.where(id: ids).pluck(:id)
        current_user.user_genres.where.not(genre_id: ids).destroy_all
        existing = current_user.user_genres.pluck(:genre_id)
        (ids - existing).each { |gid| current_user.user_genres.create!(genre_id: gid) }
      end

      def sync_favorite_books!
        ids = Array(params.dig(:me, :favorite_book_ids)).map(&:to_i).uniq
        ids &= Book.where(id: ids).pluck(:id)
        current_user.user_favorite_books.where.not(book_id: ids).destroy_all
        # position は配列順で再採番
        ids.each_with_index do |bid, idx|
          ufb = current_user.user_favorite_books.find_or_initialize_by(book_id: bid)
          ufb.position = idx
          ufb.save!
        end
      end
    end
  end
end
