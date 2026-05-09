class ApplicationController < ActionController::API
  # =====================================================================
  # 例外ハンドリング：API 全体で統一されたエラー JSON を返す共通ハンドラ
  # =====================================================================
  rescue_from ActiveRecord::RecordNotFound,       with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid,        with: :render_validation_failed
  rescue_from ActiveRecord::RecordNotUnique,      with: :render_conflict
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  protected

  # 認証必須エンドポイントで未ログイン時の 401 を統一
  def authenticate_user!
    return if user_signed_in?

    render_error(:unauthenticated, "ログインが必要です", status: :unauthorized)
  end

  # 共通エラーレンダラ。全コントローラから利用する想定。
  def render_error(code, message, status:, details: nil)
    body = { error: { code: code, message: message } }
    body[:error][:details] = details if details
    render json: body, status: status
  end

  private

  def render_not_found(_e)
    render_error(:not_found, "リソースが見つかりません", status: :not_found)
  end

  def render_validation_failed(e)
    details = e.record.errors.map { |err| { field: err.attribute, message: err.full_message } }
    render_error(:validation_failed, "入力内容に誤りがあります",
                 status: :unprocessable_entity, details: details)
  end

  def render_conflict(_e)
    render_error(:conflict, "重複しています", status: :conflict)
  end

  def render_bad_request(e)
    render_error(:bad_request, "リクエストパラメータが不正です: #{e.param}", status: :bad_request)
  end
end
