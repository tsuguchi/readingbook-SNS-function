# CORS（クロスオリジンリソース共有）設定
#
# Next.js（フロントエンド）から Rails API（バックエンド）への通信を許可する。
# JWT を Authorization ヘッダで送る前提のため、Authorization ヘッダの expose を必須とする。

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 許可オリジン（複数指定可）。本番では固定 URL に絞る。
    # ENV["FRONTEND_ORIGINS"] が設定されていればカンマ区切りで上書き可。
    origins(*ENV.fetch("FRONTEND_ORIGINS", "http://localhost:3000,http://localhost:3010").split(","))

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             # フロントエンドが Authorization ヘッダを取得して保存できるよう露出
             expose: %w[Authorization X-Request-Id],
             # Cookie / 認証情報の送信を許可（将来 httpOnly Cookie 化する場合に備える）
             credentials: false
  end
end
