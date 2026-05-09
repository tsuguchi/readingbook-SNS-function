require "rails_helper"

RSpec.describe "Api::V1::Timeline", type: :request do
  let(:me)        { create(:user) }
  let(:friend)    { create(:user) }
  let(:stranger)  { create(:user) }
  let(:me_auth)   { auth_headers(me) }

  describe "GET /api/v1/timeline/home" do
    before do
      Follow.create!(follower: me, followee: friend, status: "accepted")
      create(:post, user: friend, body: "friend post 1")
      create(:post, user: friend, body: "friend post 2")
      create(:post, user: stranger, body: "stranger post")
      create(:post, user: me, body: "self post")
    end

    it "自分とフォロー中ユーザーの投稿が新着順で返る" do
      get "/api/v1/timeline/home", headers: me_auth
      expect(response).to have_http_status(:ok)
      bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
      expect(bodies).to contain_exactly("friend post 1", "friend post 2", "self post")
    end

    it "ミュート対象の投稿は除外される（要件 MU-02）" do
      Mute.create!(muter: me, muted: friend)
      get "/api/v1/timeline/home", headers: me_auth
      bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
      expect(bodies).to eq([ "self post" ])
    end

    it "ブロック関係にあるユーザーの投稿は除外される" do
      Block.create!(blocker: me, blocked: friend)
      Follow.where(follower: me, followee: friend).destroy_all # ブロック後は関係解除済の前提
      get "/api/v1/timeline/home", headers: me_auth
      bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
      expect(bodies).to eq([ "self post" ])
    end

    it "論理削除済み投稿は表示されない" do
      Post.where(body: "friend post 1").update_all(deleted_at: Time.current)
      get "/api/v1/timeline/home", headers: me_auth
      bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
      expect(bodies).not_to include("friend post 1")
    end
  end

  describe "GET /api/v1/timeline/explore" do
    before do
      create(:post, user: friend, body: "public 1")
      create(:post, user: stranger, body: "public 2")
      private_user = create(:user, is_private: true)
      create(:post, user: private_user, body: "private")
    end

    it "公開アカウントの投稿のみ返す（自分の投稿は除外）" do
      create(:post, user: me, body: "my own post")
      get "/api/v1/timeline/explore", headers: me_auth
      bodies = JSON.parse(response.body)["data"].map { |p| p.dig("attributes", "body") }
      expect(bodies).to contain_exactly("public 1", "public 2")
    end
  end
end
