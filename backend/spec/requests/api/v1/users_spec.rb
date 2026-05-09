require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  let(:viewer)      { create(:user) }
  let(:author)      { create(:user) }
  let(:viewer_auth) { auth_headers(viewer) }

  describe "GET /api/v1/users/:handle" do
    it "プロフィールを取得できる" do
      get "/api/v1/users/#{author.handle}", headers: viewer_auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "attributes", "handle")).to eq(author.handle)
    end

    it "存在しないハンドルは 404" do
      get "/api/v1/users/nonexistent_handle", headers: viewer_auth
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/users/:handle/posts" do
    before do
      create(:post, user: author, body: "post 1")
      create(:post, user: author, body: "post 2")
    end

    it "対象ユーザーの投稿一覧を新着順で返す" do
      get "/api/v1/users/#{author.handle}/posts", headers: viewer_auth
      expect(response).to have_http_status(:ok)
      bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
      expect(bodies).to eq([ "post 2", "post 1" ])
    end

    it "非公開アカウントの投稿はフォロワー以外に 403" do
      author.update!(is_private: true)
      get "/api/v1/users/#{author.handle}/posts", headers: viewer_auth
      expect(response).to have_http_status(:forbidden)
    end

    it "非公開アカウントでもフォロワーは閲覧可能" do
      author.update!(is_private: true)
      Follow.create!(follower: viewer, followee: author, status: "accepted")
      get "/api/v1/users/#{author.handle}/posts", headers: viewer_auth
      expect(response).to have_http_status(:ok)
    end

    it "本人は自分の非公開投稿を見られる" do
      author.update!(is_private: true)
      get "/api/v1/users/#{author.handle}/posts", headers: auth_headers(author)
      expect(response).to have_http_status(:ok)
    end
  end
end
