require "rails_helper"

RSpec.describe "Api::V1::Comments", type: :request do
  let(:user)         { create(:user) }
  let(:other_user)   { create(:user) }
  let(:target_post)  { create(:post, user: user) }
  let(:auth)         { auth_headers(user) }
  let(:other_auth)   { auth_headers(other_user) }

  describe "POST /api/v1/posts/:post_id/comments" do
    it "コメントを作成できる" do
      expect {
        post "/api/v1/posts/#{target_post.id}/comments",
             params: { comment: { body: "面白いですね" } }.to_json,
             headers: other_auth.merge("Content-Type" => "application/json")
      }.to change(Comment, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /api/v1/posts/:post_id/comments" do
    before do
      create(:comment, post: target_post, user: other_user, body: "first")
      create(:comment, post: target_post, user: user, body: "second")
    end

    it "コメント一覧を返す" do
      get "/api/v1/posts/#{target_post.id}/comments", headers: auth
      expect(response).to have_http_status(:ok)
      bodies = JSON.parse(response.body)["data"].map { |c| c.dig("attributes", "body") }
      expect(bodies).to eq(%w[first second])
    end
  end

  describe "PATCH /api/v1/comments/:id" do
    let!(:comment) { create(:comment, post: target_post, user: other_user, body: "old") }

    it "コメント本人は編集できる" do
      patch "/api/v1/comments/#{comment.id}",
            params: { comment: { body: "new" } }.to_json,
            headers: other_auth.merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:ok)
    end

    it "他人は編集できない" do
      patch "/api/v1/comments/#{comment.id}",
            params: { comment: { body: "hacked" } }.to_json,
            headers: auth.merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/comments/:id" do
    let!(:comment) { create(:comment, post: target_post, user: other_user) }

    it "コメント本人は削除できる" do
      delete "/api/v1/comments/#{comment.id}", headers: other_auth
      expect(response).to have_http_status(:no_content)
    end

    it "投稿者は他人のコメントも削除できる（モデレーション権限）" do
      delete "/api/v1/comments/#{comment.id}", headers: auth
      expect(response).to have_http_status(:no_content)
    end

    it "無関係な第三者は削除できない" do
      stranger = create(:user)
      delete "/api/v1/comments/#{comment.id}", headers: auth_headers(stranger)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
