# Request spec で JWT 認証を簡単に行うためのヘルパ。
# spec/rails_helper.rb で include すること。
module AuthHelpers
  # 指定ユーザーで認証済みのリクエストヘッダを返す。
  # devise-jwt の Warden::JWTAuth::UserEncoder を直接使ってトークンを生成する。
  def auth_headers(user)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    { "Authorization" => "Bearer #{token}" }
  end
end
