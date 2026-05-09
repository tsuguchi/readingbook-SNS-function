require "rails_helper"

RSpec.describe "Api::V1::Reposts", type: :request do
  let(:author)        { create(:user) }
  let(:reposter)      { create(:user) }
  let(:other)         { create(:user) }
  let(:target_post)   { create(:post, user: author) }
  let(:author_auth)   { auth_headers(author) }
  let(:reposter_auth) { auth_headers(reposter) }
  let(:other_auth)    { auth_headers(other) }

  describe "POST /api/v1/posts/:post_id/repost" do
    it "単純リポストを作成し is_reposted: true を返す" do
      expect {
        post "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
      }.to change(Repost, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "is_reposted")).to eq(true)
      expect(JSON.parse(response.body).dig("data", "reposts_count")).to eq(1)
    end

    it "2 回目の POST はトグル取消（要件 RP-03）" do
      post "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
      expect {
        post "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
      }.to change(Repost, :count).by(-1)
      expect(JSON.parse(response.body).dig("data", "is_reposted")).to eq(false)
    end

    it "通知が元投稿者に送られる（要件 RP-N-01）" do
      expect {
        post "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
      }.to change { Notification.where(notification_type: "repost").count }.by(1)
    end

    context "非公開アカウントの投稿（要件 RP-08）" do
      before { author.update!(is_private: true) }

      it "リポスト不可で 404" do
        post "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
        expect(response).to have_http_status(:not_found)
      end
    end

    context "ブロック関係（要件 RP-09）" do
      before { Block.create!(blocker: author, blocked: reposter) }

      it "リポスト不可で 404" do
        post "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /api/v1/posts/:post_id/repost" do
    it "単純リポストを削除する（冪等）" do
      Repost.create!(user: reposter, post: target_post, repost_type: "simple")
      expect {
        delete "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
      }.to change(Repost, :count).by(-1)
      expect(JSON.parse(response.body).dig("data", "is_reposted")).to eq(false)
    end

    it "未リポストでも 200（冪等）" do
      delete "/api/v1/posts/#{target_post.id}/repost", headers: reposter_auth
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /api/v1/posts/:post_id/quote_repost" do
    it "引用リポストを作成する" do
      expect {
        post "/api/v1/posts/#{target_post.id}/quote_repost",
             params: { repost: { comment: "必読" } }.to_json,
             headers: reposter_auth.merge("Content-Type" => "application/json")
      }.to change { Repost.where(repost_type: "quote").count }.by(1)
      expect(response).to have_http_status(:created)
    end

    it "コメント空は 422" do
      post "/api/v1/posts/#{target_post.id}/quote_repost",
           params: { repost: { comment: "" } }.to_json,
           headers: reposter_auth.merge("Content-Type" => "application/json")
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "通知タイプは quote_repost" do
      expect {
        post "/api/v1/posts/#{target_post.id}/quote_repost",
             params: { repost: { comment: "感想" } }.to_json,
             headers: reposter_auth.merge("Content-Type" => "application/json")
      }.to change { Notification.where(notification_type: "quote_repost").count }.by(1)
    end
  end

  describe "GET /api/v1/posts/:post_id/reposts" do
    before do
      Repost.create!(user: reposter, post: target_post, repost_type: "simple")
      Repost.create!(user: other, post: target_post, repost_type: "quote", comment: "良い")
    end

    it "元投稿のリポスト一覧を返す（要件 RP-05）" do
      get "/api/v1/posts/#{target_post.id}/reposts", headers: author_auth
      expect(response).to have_http_status(:ok)
      types = JSON.parse(response.body)["data"].map { |r| r.dig("attributes", "repost_type") }
      expect(types).to contain_exactly("simple", "quote")
    end
  end

  describe "DELETE /api/v1/reposts/:id" do
    let!(:quote) { Repost.create!(user: reposter, post: target_post, repost_type: "quote", comment: "x") }

    it "本人は引用リポストを削除できる" do
      delete "/api/v1/reposts/#{quote.id}", headers: reposter_auth
      expect(response).to have_http_status(:no_content)
      expect(Repost.exists?(quote.id)).to eq(false)
    end

    it "他人は削除できない（403）" do
      delete "/api/v1/reposts/#{quote.id}", headers: other_auth
      expect(response).to have_http_status(:forbidden)
    end
  end
end
