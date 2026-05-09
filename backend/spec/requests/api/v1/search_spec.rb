require "rails_helper"

RSpec.describe "Api::V1::Search", type: :request do
  let(:viewer)      { create(:user, handle: "viewer1", display_name: "Viewer") }
  let(:viewer_auth) { auth_headers(viewer) }

  let!(:alice) { create(:user, handle: "alice_search", display_name: "Alice") }
  let!(:bob)   { create(:user, handle: "bob_search",   display_name: "Bob") }
  let!(:book_a) { Book.create!(title: "リーダブルコード", author: "Boswell", isbn: "9780000000001") }
  let!(:book_b) { Book.create!(title: "Refactoring",     author: "Fowler",   isbn: "9780000000002") }
  let!(:post_a) { create(:post, user: alice, body: "リーダブルコードを読了") }
  let!(:tag)    { Hashtag.create!(name: "感想") }

  describe "GET /api/v1/search" do
    it "type=users で部分一致" do
      get "/api/v1/search", params: { q: "alice", type: "users" }, headers: viewer_auth
      expect(response).to have_http_status(:ok)
      handles = JSON.parse(response.body).dig("data", "users").map { |u| u.dig("attributes", "handle") }
      expect(handles).to include("alice_search")
    end

    it "type=books でタイトル / 著者検索" do
      get "/api/v1/search", params: { q: "Fowler", type: "books" }, headers: viewer_auth
      titles = JSON.parse(response.body).dig("data", "books").map { |b| b.dig("attributes", "title") }
      expect(titles).to eq([ "Refactoring" ])
    end

    it "type=books で ISBN 完全一致" do
      get "/api/v1/search", params: { q: "9780000000001", type: "books" }, headers: viewer_auth
      titles = JSON.parse(response.body).dig("data", "books").map { |b| b.dig("attributes", "title") }
      expect(titles).to eq([ "リーダブルコード" ])
    end

    it "type=posts で本文検索" do
      get "/api/v1/search", params: { q: "リーダブル", type: "posts" }, headers: viewer_auth
      bodies = JSON.parse(response.body).dig("data", "posts").map { |p| p.dig("attributes", "body") }
      expect(bodies).to include(post_a.body)
    end

    it "type=tags でハッシュタグ検索（# プレフィックスは除去）" do
      get "/api/v1/search", params: { q: "#感想", type: "tags" }, headers: viewer_auth
      names = JSON.parse(response.body).dig("data", "tags").map { |t| t.dig("attributes", "name") }
      expect(names).to eq([ "感想" ])
    end

    it "type 未指定 (all) で 4 カテゴリすべて返す" do
      get "/api/v1/search", params: { q: "リーダブル" }, headers: viewer_auth
      data = JSON.parse(response.body)["data"]
      expect(data.keys).to contain_exactly("users", "books", "posts", "tags")
    end

    it "ブロックされたユーザーは結果から除外（要件 SR-05）" do
      Block.create!(blocker: alice, blocked: viewer)
      get "/api/v1/search", params: { q: "alice", type: "users" }, headers: viewer_auth
      handles = JSON.parse(response.body).dig("data", "users").map { |u| u.dig("attributes", "handle") }
      expect(handles).not_to include("alice_search")
    end

    it "非公開アカウントの投稿は除外される（要件 SR-04）" do
      alice.update!(is_private: true)
      get "/api/v1/search", params: { q: "リーダブル", type: "posts" }, headers: viewer_auth
      bodies = JSON.parse(response.body).dig("data", "posts").map { |p| p.dig("attributes", "body") }
      expect(bodies).not_to include(post_a.body)
    end

    it "空クエリは空結果を返し、履歴も記録しない" do
      expect {
        get "/api/v1/search", params: { q: "" }, headers: viewer_auth
      }.not_to change(SearchHistory, :count)
      expect(response).to have_http_status(:ok)
    end

    it "検索を実行すると検索履歴が記録される（要件 SR-06）" do
      expect {
        get "/api/v1/search", params: { q: "alice", type: "users" }, headers: viewer_auth
      }.to change { viewer.search_histories.count }.by(1)

      history = viewer.search_histories.last
      expect(history.query).to eq("alice")
      expect(history.category).to eq("users")
    end
  end

  describe "GET /api/v1/search/suggest" do
    it "ユーザーの前方一致候補を返す（要件 SR-07）" do
      get "/api/v1/search/suggest", params: { q: "alice", type: "users" }, headers: viewer_auth
      labels = JSON.parse(response.body)["data"].map { |i| i["sublabel"] }
      expect(labels).to include("@alice_search")
    end
  end

  describe "履歴管理（要件 SR-06）" do
    let!(:h1) { SearchHistory.create!(user: viewer, query: "x", executed_at: 2.days.ago) }
    let!(:h2) { SearchHistory.create!(user: viewer, query: "y", executed_at: 1.day.ago) }

    it "GET /api/v1/me/search_histories で取得（新着順）" do
      get "/api/v1/me/search_histories", headers: viewer_auth
      queries = JSON.parse(response.body)["data"].map { |h| h["query"] }
      expect(queries).to eq(%w[y x])
    end

    it "DELETE /api/v1/me/search_histories/:id 個別削除" do
      delete "/api/v1/me/search_histories/#{h1.id}", headers: viewer_auth
      expect(response).to have_http_status(:no_content)
      expect(SearchHistory.exists?(h1.id)).to eq(false)
    end

    it "DELETE /api/v1/me/search_histories で一括削除" do
      delete "/api/v1/me/search_histories", headers: viewer_auth
      expect(response).to have_http_status(:no_content)
      expect(viewer.reload.search_histories.count).to eq(0)
    end
  end
end
