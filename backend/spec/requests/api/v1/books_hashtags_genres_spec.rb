require "rails_helper"

RSpec.describe "Api::V1::Books / Hashtags / Genres", type: :request do
  let(:user)      { create(:user) }
  let(:user_auth) { auth_headers(user) }

  describe "Books" do
    describe "POST /api/v1/books" do
      it "本を登録できる" do
        expect {
          post "/api/v1/books",
               params: { book: { title: "Sample", author: "Author", isbn: "9784000000001" } }.to_json,
               headers: user_auth.merge("Content-Type" => "application/json")
        }.to change(Book, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "ISBN 重複は 409" do
        Book.create!(title: "X", isbn: "9784000000002")
        post "/api/v1/books",
             params: { book: { title: "Y", isbn: "9784000000002" } }.to_json,
             headers: user_auth.merge("Content-Type" => "application/json")
        expect(response).to have_http_status(:conflict).or(have_http_status(:unprocessable_entity))
      end
    end

    describe "GET /api/v1/books" do
      before do
        Book.create!(title: "リーダブルコード", author: "Boswell")
        Book.create!(title: "プログラマの三大美徳", author: "Larry")
      end

      it "?q= でタイトル / 著者を部分一致検索できる" do
        # 日本語クエリは URI encode してから渡す（rack-test の URI パーサが ASCII のみ受付）
        get "/api/v1/books", params: { q: "リーダブル" }, headers: user_auth
        titles = JSON.parse(response.body)["data"].map { |b| b.dig("attributes", "title") }
        expect(titles).to eq([ "リーダブルコード" ])

        get "/api/v1/books", params: { q: "Larry" }, headers: user_auth
        titles = JSON.parse(response.body)["data"].map { |b| b.dig("attributes", "title") }
        expect(titles).to eq([ "プログラマの三大美徳" ])
      end
    end

    describe "GET /api/v1/books/:id" do
      let!(:book) { Book.create!(title: "Test") }

      it "詳細を取得できる（counts / is_liked 含む）" do
        get "/api/v1/books/#{book.id}", headers: user_auth
        expect(response).to have_http_status(:ok)
        attrs = JSON.parse(response.body).dig("data", "attributes")
        expect(attrs["title"]).to eq("Test")
        expect(attrs["counts"]).to include("likes" => 0, "posts" => 0)
        expect(attrs["is_liked"]).to eq(false)
      end
    end

    describe "GET /api/v1/books/:book_id/posts" do
      let!(:book)   { Book.create!(title: "Linked") }
      let!(:author) { create(:user) }
      let!(:p1)     { create(:post, user: author, book: book, body: "p1") }

      it "この本に紐づく投稿一覧" do
        get "/api/v1/books/#{book.id}/posts", headers: user_auth
        bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
        expect(bodies).to include("p1")
      end

      it "非公開アカウントの投稿は除外される" do
        author.update!(is_private: true)
        get "/api/v1/books/#{book.id}/posts", headers: user_auth
        bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
        expect(bodies).not_to include("p1")
      end
    end
  end

  describe "Hashtags" do
    let!(:tag)     { Hashtag.create!(name: "読了") }
    let!(:author)  { create(:user) }
    let!(:tagged_post) { create(:post, user: author, body: "本文 #読了") }

    before do
      tagged_post.hashtags << tag
    end

    describe "GET /api/v1/hashtags/:name" do
      it "詳細（投稿件数）を返す" do
        get "/api/v1/hashtags/#{CGI.escape(tag.name)}", headers: user_auth
        expect(response).to have_http_status(:ok)
        attrs = JSON.parse(response.body).dig("data", "attributes")
        expect(attrs["name"]).to eq("読了")
        expect(attrs["counts"]["posts"]).to eq(1)
      end

      it "存在しないタグは 404" do
        get "/api/v1/hashtags/nonexistent", headers: user_auth
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "GET /api/v1/hashtags/:hashtag_name/posts" do
      it "そのタグが付いた投稿一覧" do
        get "/api/v1/hashtags/#{CGI.escape(tag.name)}/posts", headers: user_auth
        bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
        expect(bodies).to include(tagged_post.body)
      end
    end
  end

  describe "Genres" do
    describe "GET /api/v1/genres" do
      before do
        Genre.create!(name: "小説")
        Genre.create!(name: "技術書")
      end

      it "ジャンル一覧を返す" do
        get "/api/v1/genres", headers: user_auth
        expect(response).to have_http_status(:ok)
        names = JSON.parse(response.body)["data"].map { |g| g["name"] }
        expect(names).to contain_exactly("小説", "技術書")
      end
    end
  end
end
