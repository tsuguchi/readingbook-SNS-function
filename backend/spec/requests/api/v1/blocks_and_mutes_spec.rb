require "rails_helper"

RSpec.describe "Api::V1::Users::Blocks & Mutes", type: :request do
  let(:alice)      { create(:user) }
  let(:bob)        { create(:user) }
  let(:alice_auth) { auth_headers(alice) }
  let(:bob_auth)   { auth_headers(bob) }

  describe "POST /api/v1/users/:user_handle/block" do
    it "ブロックを作成し、双方向のフォロー関係を解除する（要件 BL-02）" do
      Follow.create!(follower: alice, followee: bob, status: "accepted")
      Follow.create!(follower: bob,   followee: alice, status: "accepted")

      expect {
        post "/api/v1/users/#{bob.handle}/block", headers: alice_auth
      }.to change(Follow, :count).by(-2)

      expect(response).to have_http_status(:created)
      expect(Block.find_by(blocker: alice, blocked: bob)).to be_present
    end

    it "ブロック対象の投稿への既存いいねを削除する（要件 LK-08）" do
      target_post = create(:post, user: bob)
      Like.create!(user: alice, target: target_post)

      expect {
        post "/api/v1/users/#{bob.handle}/block", headers: alice_auth
      }.to change(Like, :count).by(-1)
    end

    it "自分自身をブロックすると 422" do
      post "/api/v1/users/#{alice.handle}/block", headers: alice_auth
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /api/v1/users/:user_handle/block" do
    it "ブロック解除（冪等）" do
      Block.create!(blocker: alice, blocked: bob)
      delete "/api/v1/users/#{bob.handle}/block", headers: alice_auth
      expect(response).to have_http_status(:no_content)
      expect(Block.exists?(blocker: alice, blocked: bob)).to eq(false)
    end
  end

  describe "GET /api/v1/me/blocks" do
    it "自分がブロックしたユーザー一覧" do
      Block.create!(blocker: alice, blocked: bob)
      get "/api/v1/me/blocks", headers: alice_auth
      expect(response).to have_http_status(:ok)
      handles = JSON.parse(response.body)["data"].map { |u| u.dig("attributes", "handle") }
      expect(handles).to eq([ bob.handle ])
    end
  end

  describe "POST /api/v1/users/:user_handle/mute" do
    it "ミュートを作成し、フォロー関係には影響しない（要件 MU-03）" do
      Follow.create!(follower: alice, followee: bob, status: "accepted")
      expect {
        post "/api/v1/users/#{bob.handle}/mute", headers: alice_auth
      }.to change(Mute, :count).by(1)
       .and(not_change(Follow, :count))

      expect(response).to have_http_status(:created)
    end

    it "自分自身をミュートすると 422" do
      post "/api/v1/users/#{alice.handle}/mute", headers: alice_auth
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/v1/me/mutes" do
    it "自分がミュートしたユーザー一覧" do
      Mute.create!(muter: alice, muted: bob)
      get "/api/v1/me/mutes", headers: alice_auth
      handles = JSON.parse(response.body)["data"].map { |u| u.dig("attributes", "handle") }
      expect(handles).to eq([ bob.handle ])
    end
  end

  RSpec::Matchers.define_negated_matcher :not_change, :change
end
