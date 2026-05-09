# LikesController 群で共通する create / destroy アクションを提供する concern。
# include 側のクラスは:
#   - find_target → @target に対象オブジェクトを設定する before_action を持つ
#   - target_owner（任意）→ Comment/Post なら投稿者、Book なら nil を返す
# ことを期待する。
module LikeAction
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :find_target
  end

  # POST /…/like
  def create
    service = LikeToggleService.new(user: current_user, target: @target)
    service.like!

    render json: {
      data: {
        is_liked: true,
        likes_count: service.likes_count
      }
    }, status: :ok
  rescue LikeToggleService::LikeForbidden
    # ブロック関係の場合は 404 で存在を秘匿（要件 BL-03）
    render_error(:not_found, "リソースが見つかりません", status: :not_found)
  end

  # DELETE /…/like
  def destroy
    service = LikeToggleService.new(user: current_user, target: @target)
    service.unlike!

    render json: {
      data: {
        is_liked: false,
        likes_count: service.likes_count
      }
    }, status: :ok
  end
end
