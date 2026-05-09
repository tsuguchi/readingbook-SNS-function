# 横断検索サービス。
# ユーザー / 本 / 投稿 / ハッシュタグ の 4 カテゴリを 1 リクエストで検索する。
#
# プライバシー / ブロックの扱い（要件 SR-04 / SR-05）:
#   - 投稿: 公開アカウントの投稿のみ + 自分の投稿（プライベートでも自分のは見える）
#   - ユーザー: ブロック関係のあるユーザーは検索結果から除外
#   - 本 / タグ: アクセス制御なし（公開マスタ）
class SearchService
  CATEGORIES = %w[all users books posts tags].freeze

  def initialize(query:, current_user:, type: "all", limit: 20, offset: 0)
    @query = query.to_s.strip
    @current_user = current_user
    @type = CATEGORIES.include?(type) ? type : "all"
    @limit = [ limit.to_i, 100 ].min.clamp(1, 100)
    @offset = [ offset.to_i, 0 ].max
  end

  def call
    return empty_result if @query.empty?

    case @type
    when "users"
      { users: users }
    when "books"
      { books: books }
    when "posts"
      { posts: posts }
    when "tags"
      { tags: tags }
    else
      { users: users.limit(5), books: books.limit(5), posts: posts.limit(5), tags: tags.limit(5) }
    end
  end

  private

  def empty_result
    @type == "all" ? { users: [], books: [], posts: [], tags: [] } : { @type.to_sym => [] }
  end

  def users
    User.where("handle ILIKE :q OR display_name ILIKE :q", q: "%#{escape(@query)}%")
        .where.not(id: blocked_user_ids)
        .order(:handle)
        .limit(@limit)
        .offset(@offset)
  end

  def books
    Book.where("title ILIKE :q OR author ILIKE :q OR isbn = :exact",
               q: "%#{escape(@query)}%", exact: @query)
        .order(:title)
        .limit(@limit)
        .offset(@offset)
  end

  def posts
    Post.alive
        .joins(:user)
        .where("posts.body ILIKE ?", "%#{escape(@query)}%")
        .where("users.is_private = false OR users.id = ?", @current_user.id)
        .where.not(user_id: blocked_user_ids)
        .includes(:user, :book, :hashtags)
        .order(created_at: :desc)
        .limit(@limit)
        .offset(@offset)
  end

  def tags
    Hashtag.where("name ILIKE ?", "%#{escape(@query.delete_prefix('#').delete_prefix('＃'))}%")
           .order(:name)
           .limit(@limit)
           .offset(@offset)
  end

  # SR-05: 双方向ブロックされたユーザーは検索結果から除外
  def blocked_user_ids
    a = Block.where(blocker: @current_user).pluck(:blocked_id)
    b = Block.where(blocked: @current_user).pluck(:blocker_id)
    (a + b).uniq
  end

  # ILIKE のメタ文字をエスケープ
  def escape(str)
    str.gsub(/([\\%_])/) { "\\#{Regexp.last_match(1)}" }
  end
end
