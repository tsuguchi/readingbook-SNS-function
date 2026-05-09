module Api
  module V1
    # GET /api/v1/search?q=&type=all|users|books|posts|tags
    # GET /api/v1/search/suggest?q=&type=users|books|tags
    class SearchController < BaseController
      def index
        result = SearchService.new(
          query: params[:q],
          current_user: current_user,
          type: params[:type],
          limit: params[:limit],
          offset: params[:offset]
        ).call

        # 検索履歴を記録（要件 SR-06）。空クエリは記録しない
        record_history!(params[:q], params[:type]) if params[:q].present?

        render json: serialize(result), status: :ok
      end

      def suggest
        type = (%w[users books tags].include?(params[:type]) ? params[:type] : "users")
        limit = [ params.fetch(:limit, 10).to_i, 20 ].min

        items =
          case type
          when "users"
            User.where("handle ILIKE :q OR display_name ILIKE :q", q: "#{escape(params[:q].to_s)}%")
                .order(:handle)
                .limit(limit)
                .map { |u| { id: u.id.to_s, label: u.display_name, sublabel: "@#{u.handle}",
                             avatar_url: u.avatar_url } }
          when "books"
            Book.where("title ILIKE ?", "#{escape(params[:q].to_s)}%")
                .order(:title)
                .limit(limit)
                .map { |b| { id: b.id.to_s, label: b.title, sublabel: b.author,
                             cover_url: b.cover_url } }
          when "tags"
            Hashtag.where("name ILIKE ?", "#{escape(params[:q].to_s.delete_prefix('#'))}%")
                   .order(:name)
                   .limit(limit)
                   .map { |t| { id: t.id.to_s, label: "##{t.name}" } }
          end

        render json: { data: items }, status: :ok
      end

      private

      def serialize(result)
        payload = {}
        payload[:users] = UserSerializer.new(result[:users]).serializable_hash[:data] if result[:users]
        if result[:books]
          payload[:books] = BookSerializer.new(result[:books],
                                               params: { current_user: current_user })
                                          .serializable_hash[:data]
        end
        if result[:posts]
          payload[:posts] = PostSerializer.new(result[:posts],
                                               params: { current_user: current_user })
                                          .serializable_hash[:data]
        end
        payload[:tags]  = HashtagSerializer.new(result[:tags]).serializable_hash[:data] if result[:tags]
        { data: payload }
      end

      def record_history!(query, type)
        SearchHistory.create!(
          user: current_user,
          query: query.to_s.strip,
          category: SearchService::CATEGORIES.include?(type.to_s) ? type : "all"
        )
      end

      def escape(str)
        str.gsub(/([\\%_])/) { "\\#{Regexp.last_match(1)}" }
      end
    end
  end
end
