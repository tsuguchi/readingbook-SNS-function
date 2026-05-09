module Api
  module V1
    # API v1 配下のコントローラの共通ベース。
    # 認証必須をデフォルトとし、公開エンドポイントは個別に skip_before_action する。
    class BaseController < ApplicationController
      before_action :authenticate_user!
    end
  end
end
