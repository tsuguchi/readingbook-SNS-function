require "rails_helper"

RSpec.describe "Api::V1::Users::Follows", type: :request do
  let(:alice)        { create(:user) }
  let(:bob)          { create(:user) }
  let(:carol)        { create(:user, is_private: true) }
  let(:alice_auth)   { auth_headers(alice) }
  let(:bob_auth)     { auth_headers(bob) }

  describe "POST /api/v1/users/:user_handle/follow" do
    it "公開アカウントへのフォローは即時 accepted" do
      post "/api/v1/users/#{alice.handle}/follow", headers: bob_auth
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("data", "status")).to eq("accepted")
      expect(Follow.find_by(follower: bob, followee: alice).status).to eq("accepted")
    end

    it "非公開アカウントへのフォローは pending（リクエスト保留）" do
      post "/api/v1/users/#{carol.handle}/follow", headers: bob_auth
      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body.dig("data", "status")).to eq("pending")
    end

    it "自分自身へのフォローは 422" do
      post "/api/v1/users/#{bob.handle}/follow", headers: bob_auth
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "ブロック関係があると 404（要件 BL-03 整合）" do
      Block.create!(blocker: alice, blocked: bob)
      post "/api/v1/users/#{alice.handle}/follow", headers: bob_auth
      expect(response).to have_http_status(:not_found)
    end

    it "通知が作成される（公開アカウント=follow / 非公開=follow_request）" do
      expect {
        post "/api/v1/users/#{alice.handle}/follow", headers: bob_auth
      }.to change { Notification.where(notification_type: "follow").count }.by(1)

      expect {
        post "/api/v1/users/#{carol.handle}/follow", headers: bob_auth
      }.to change { Notification.where(notification_type: "follow_request").count }.by(1)
    end
  end

  describe "DELETE /api/v1/users/:user_handle/follow" do
    it "フォロー解除（冪等）" do
      Follow.create!(follower: bob, followee: alice, status: "accepted")
      expect {
        delete "/api/v1/users/#{alice.handle}/follow", headers: bob_auth
      }.to change(Follow, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "GET /api/v1/users/:user_handle/followers" do
    before { Follow.create!(follower: bob, followee: alice, status: "accepted") }

    it "公開アカウントのフォロワー一覧は誰でも取得できる" do
      get "/api/v1/users/#{alice.handle}/followers", headers: bob_auth
      expect(response).to have_http_status(:ok)
      handles = JSON.parse(response.body)["data"].map { |u| u.dig("attributes", "handle") }
      expect(handles).to include(bob.handle)
    end

    it "非公開アカウントのフォロワーはフォロワー以外には 403" do
      Follow.create!(follower: bob, followee: carol, status: "accepted")
      stranger = create(:user)
      get "/api/v1/users/#{carol.handle}/followers", headers: auth_headers(stranger)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /api/v1/me/follow_requests/:user_handle/accept" do
    it "保留中リクエストを accepted に変更し、フォロー成立通知を送る" do
      Follow.create!(follower: bob, followee: carol, status: "pending")

      expect {
        post "/api/v1/me/follow_requests/#{bob.handle}/accept", headers: auth_headers(carol)
      }.to change { Notification.where(notification_type: "follow_accepted").count }.by(1)

      expect(response).to have_http_status(:no_content)
      expect(Follow.find_by(follower: bob, followee: carol).status).to eq("accepted")
    end
  end

  describe "POST /api/v1/me/follow_requests/:user_handle/reject" do
    it "保留中リクエストを削除し、通知は送らない" do
      Follow.create!(follower: bob, followee: carol, status: "pending")

      expect {
        post "/api/v1/me/follow_requests/#{bob.handle}/reject", headers: auth_headers(carol)
      }.to change(Follow, :count).by(-1)
       .and(not_change { Notification.count })

      expect(response).to have_http_status(:no_content)
    end

    RSpec::Matchers.define_negated_matcher :not_change, :change
  end
end
