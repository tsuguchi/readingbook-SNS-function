require "rails_helper"

RSpec.describe "Api::V1::Posts", type: :request do
  let(:user)         { create(:user) }
  let(:other_user)   { create(:user) }
  let(:auth)         { auth_headers(user) }
  let(:other_auth)   { auth_headers(other_user) }

  describe "POST /api/v1/posts" do
    context "認証済みユーザー" do
      it "投稿を作成できる" do
        expect {
          post "/api/v1/posts",
               params: { post: { body: "Hello world" } }.to_json,
               headers: auth.merge("Content-Type" => "application/json")
        }.to change(Post, :count).by(1)

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body.dig("data", "attributes", "body")).to eq("Hello world")
      end

      it "本文中の #タグ がハッシュタグとして登録される" do
        post "/api/v1/posts",
             params: { post: { body: "今日は #読書 の日 #秋の夜長" } }.to_json,
             headers: auth.merge("Content-Type" => "application/json")

        expect(response).to have_http_status(:created)
        body = JSON.parse(response.body)
        expect(body.dig("data", "attributes", "hashtags")).to contain_exactly("読書", "秋の夜長")
      end
    end

    context "未認証" do
      it "401 を返す" do
        post "/api/v1/posts",
             params: { post: { body: "Hello" } }.to_json,
             headers: { "Content-Type" => "application/json" }
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/posts/:id" do
    let!(:target_post) { create(:post, user: user, body: "本文") }

    it "投稿詳細を返す" do
      get "/api/v1/posts/#{target_post.id}", headers: auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "attributes", "body")).to eq("本文")
    end

    it "論理削除済み投稿は 404" do
      target_post.update!(deleted_at: Time.current)
      get "/api/v1/posts/#{target_post.id}", headers: auth
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /api/v1/posts/:id" do
    let!(:target_post) { create(:post, user: user, body: "old") }

    it "本人は編集できる" do
      patch "/api/v1/posts/#{target_post.id}",
            params: { post: { body: "new" } }.to_json,
            headers: auth.merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:ok)
      expect(target_post.reload.body).to eq("new")
    end

    it "他人の投稿は編集できない (403)" do
      patch "/api/v1/posts/#{target_post.id}",
            params: { post: { body: "hacked" } }.to_json,
            headers: other_auth.merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/posts/:id" do
    let!(:target_post) { create(:post, user: user) }

    it "本人は論理削除できる" do
      delete "/api/v1/posts/#{target_post.id}", headers: auth
      expect(response).to have_http_status(:no_content)
      expect(target_post.reload.deleted_at).to be_present
    end

    it "他人の投稿は削除できない (403)" do
      delete "/api/v1/posts/#{target_post.id}", headers: other_auth
      expect(response).to have_http_status(:forbidden)
    end
  end
end
