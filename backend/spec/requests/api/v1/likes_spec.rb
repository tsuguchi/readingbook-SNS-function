require "rails_helper"

RSpec.describe "Api::V1::Likes", type: :request do
  let(:author)      { create(:user) }
  let(:liker)       { create(:user) }
  let(:other)       { create(:user) }
  let(:author_auth) { auth_headers(author) }
  let(:liker_auth)  { auth_headers(liker) }
  let(:other_auth)  { auth_headers(other) }
  let(:target_post) { create(:post, user: author) }

  describe "POST /api/v1/posts/:post_id/like" do
    it "いいねを作成し is_liked: true / likes_count: 1 を返す" do
      expect {
        post "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
      }.to change(Like, :count).by(1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body.dig("data", "is_liked")).to eq(true)
      expect(body.dig("data", "likes_count")).to eq(1)
    end

    it "2 回目の POST は冪等（件数は 1 のまま）" do
      post "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
      expect {
        post "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
      }.not_to change(Like, :count)
      expect(response).to have_http_status(:ok)
    end

    it "投稿者本人へ通知が作られる（自己いいねでなければ）" do
      expect {
        post "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
      }.to change(Notification, :count).by(1)
    end

    it "自己いいねでは通知が作られない（要件 LK-N-04）" do
      expect {
        post "/api/v1/posts/#{target_post.id}/like", headers: author_auth
      }.not_to change(Notification, :count)
    end

    context "ブロック関係がある場合（要件 LK-08）" do
      before { Block.create!(blocker: author, blocked: liker) }

      it "404 を返し、Like も作られない" do
        expect {
          post "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
        }.not_to change(Like, :count)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/posts/:post_id/like" do
    it "いいねを削除する" do
      Like.create!(user: liker, target: target_post)
      expect {
        delete "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
      }.to change(Like, :count).by(-1)
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "is_liked")).to eq(false)
    end

    it "未いいね状態でも冪等（200 を返す）" do
      delete "/api/v1/posts/#{target_post.id}/like", headers: liker_auth
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /api/v1/posts/:post_id/likes" do
    before { Like.create!(user: liker, target: target_post) }

    it "投稿者本人なら一覧を取得できる（要件 LK-06）" do
      get "/api/v1/posts/#{target_post.id}/likes", headers: author_auth
      expect(response).to have_http_status(:ok)
      handles = JSON.parse(response.body)["data"].map { |u| u.dig("attributes", "handle") }
      expect(handles).to include(liker.handle)
    end

    it "他人がアクセスすると 403（要件 LK-04）" do
      get "/api/v1/posts/#{target_post.id}/likes", headers: other_auth
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "GET /api/v1/me/likes" do
    let!(:like_post)    { Like.create!(user: liker, target: target_post) }
    let!(:like_comment) { Like.create!(user: liker, target: create(:comment, post: target_post, user: other)) }

    it "自分の押したいいね一覧を返す（要件 LK-05）" do
      get "/api/v1/me/likes", headers: liker_auth
      expect(response).to have_http_status(:ok)
      types = JSON.parse(response.body)["data"].map { |l| l.dig("attributes", "target_type") }
      expect(types).to contain_exactly("Post", "Comment")
    end

    it "?type=post で対象を絞り込める" do
      get "/api/v1/me/likes?type=post", headers: liker_auth
      types = JSON.parse(response.body)["data"].map { |l| l.dig("attributes", "target_type") }
      expect(types).to eq([ "Post" ])
    end
  end

  describe "POST /api/v1/comments/:comment_id/like" do
    let(:comment) { create(:comment, post: target_post, user: author) }

    it "コメントへのいいねが作成される" do
      expect {
        post "/api/v1/comments/#{comment.id}/like", headers: liker_auth
      }.to change(Like, :count).by(1)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/books/:book_id/like" do
    let(:book) { Book.create!(title: "Sample Book") }

    it "本へのいいねが作成され、通知は作られない（要件 LK-N-05）" do
      expect {
        post "/api/v1/books/#{book.id}/like", headers: liker_auth
      }.to change(Like, :count).by(1)
       .and(not_change(Notification, :count))

      expect(response).to have_http_status(:ok)
    end
  end

  # not_change matcher は標準にない。簡易マッチャを定義
  RSpec::Matchers.define_negated_matcher :not_change, :change
end
