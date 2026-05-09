require "rails_helper"

RSpec.describe "Api::V1::Notifications", type: :request do
  let(:me)        { create(:user) }
  let(:actor)     { create(:user) }
  let(:me_auth)   { auth_headers(me) }

  let!(:n_unread) do
    Notification.create!(recipient: me, actor: actor, notification_type: "follow",
                         target: Follow.create!(follower: actor, followee: me, status: "accepted"))
  end
  let!(:n_read) do
    notif = Notification.create!(recipient: me, actor: actor, notification_type: "follow_request",
                                 target: Follow.create!(follower: create(:user), followee: me, status: "pending"))
    notif.update!(read_at: Time.current)
    notif
  end

  describe "GET /api/v1/notifications" do
    it "自分宛の通知を新着順で返す" do
      get "/api/v1/notifications", headers: me_auth
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["data"].map { |n| n["id"].to_i }
      expect(ids).to include(n_unread.id, n_read.id)
    end

    it "?unread_only=true で未読のみ返す" do
      get "/api/v1/notifications?unread_only=true", headers: me_auth
      ids = JSON.parse(response.body)["data"].map { |n| n["id"].to_i }
      expect(ids).to eq([ n_unread.id ])
    end
  end

  describe "POST /api/v1/notifications/:id/read" do
    it "個別既読化（read_at セット）" do
      post "/api/v1/notifications/#{n_unread.id}/read", headers: me_auth
      expect(response).to have_http_status(:no_content)
      expect(n_unread.reload.read_at).to be_present
    end

    it "他人の通知は 404（recipient で絞っているため）" do
      stranger_auth = auth_headers(create(:user))
      post "/api/v1/notifications/#{n_unread.id}/read", headers: stranger_auth
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/notifications/read_all" do
    it "未読通知をすべて既読化" do
      post "/api/v1/notifications/read_all", headers: me_auth
      expect(response).to have_http_status(:no_content)
      expect(me.received_notifications.unread.count).to eq(0)
    end
  end

  describe "GET /api/v1/notifications/unread_count" do
    it "未読件数を返す" do
      get "/api/v1/notifications/unread_count", headers: me_auth
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).dig("data", "unread_count")).to eq(1)
    end
  end
end
