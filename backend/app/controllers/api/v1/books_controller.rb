module Api
  module V1
    # GET    /api/v1/books            一覧 / 検索（?q=, ?isbn=）
    # GET    /api/v1/books/:id        詳細
    # POST   /api/v1/books            登録（ISBN UNIQUE 衝突時は 409）
    class BooksController < BaseController
      def index
        scope = Book.all

        scope = scope.where(isbn: params[:isbn]) if params[:isbn].present?
        if params[:q].present?
          q = "%#{params[:q]}%"
          scope = scope.where("title ILIKE :q OR author ILIKE :q", q: q)
        end

        books = scope.order(:title).limit(limit).offset(offset)

        render json: BookSerializer.new(books, params: { current_user: current_user }).serializable_hash,
               status: :ok
      end

      def show
        book = Book.find(params[:id])
        render json: BookSerializer.new(book, params: { current_user: current_user }).serializable_hash,
               status: :ok
      end

      def create
        book = Book.new(book_params)
        book.save!
        render json: BookSerializer.new(book, params: { current_user: current_user }).serializable_hash,
               status: :created
      end

      private

      def book_params
        params.require(:book).permit(:title, :author, :isbn, :cover_url, :published_on)
      end

      def limit
        [ params.fetch(:limit, 20).to_i, 100 ].min
      end

      def offset
        [ params.fetch(:offset, 0).to_i, 0 ].max
      end
    end
  end
end
