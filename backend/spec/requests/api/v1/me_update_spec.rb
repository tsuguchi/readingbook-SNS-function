require "rails_helper"

RSpec.describe "Api::V1::Me PATCH", type: :request do
  let(:user)      { create(:user, bio: nil, reading_goal: nil) }
  let(:user_auth) { auth_headers(user) }

  describe "PATCH /api/v1/me" do
    it "プロフィール基本情報（display_name / bio / is_private / reading_goal）を更新できる" do
      patch "/api/v1/me",
            params: { me: { bio: "本好き", reading_goal: 50, display_name: "Updated Name" } }.to_json,
            headers: user_auth.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      user.reload
      expect(user.bio).to eq("本好き")
      expect(user.reading_goal).to eq(50)
      expect(user.display_name).to eq("Updated Name")
    end

    it "favorite_genre_ids で UserGenre を同期できる" do
      g1 = Genre.create!(name: "小説")
      g2 = Genre.create!(name: "技術書")
      g3 = Genre.create!(name: "エッセイ")

      patch "/api/v1/me",
            params: { me: { favorite_genre_ids: [ g1.id, g2.id ] } }.to_json,
            headers: user_auth.merge("Content-Type" => "application/json")

      expect(response).to have_http_status(:ok)
      expect(user.reload.genres.map(&:id)).to contain_exactly(g1.id, g2.id)

      # 別の組合せに切り替え → 差分のみ反映
      patch "/api/v1/me",
            params: { me: { favorite_genre_ids: [ g2.id, g3.id ] } }.to_json,
            headers: user_auth.merge("Content-Type" => "application/json")
      expect(user.reload.genres.map(&:id)).to contain_exactly(g2.id, g3.id)
    end

    it "favorite_book_ids で UserFavoriteBook を順序付きで同期できる" do
      b1 = Book.create!(title: "Book A")
      b2 = Book.create!(title: "Book B")

      patch "/api/v1/me",
            params: { me: { favorite_book_ids: [ b2.id, b1.id ] } }.to_json,
            headers: user_auth.merge("Content-Type" => "application/json")

      ufbs = user.user_favorite_books.order(:position)
      expect(ufbs.map(&:book_id)).to eq([ b2.id, b1.id ])
      expect(ufbs.map(&:position)).to eq([ 0, 1 ])
    end

    it "未認証では 401" do
      patch "/api/v1/me", params: { me: { bio: "x" } }.to_json,
                          headers: { "Content-Type" => "application/json" }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
