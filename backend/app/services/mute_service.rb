# ミュートの作成・解除を扱うサービス。
# ミュートはフォロー関係を維持したまま自分のタイムライン上で対象を非表示にするだけ
# なので、副作用やクリーンアップは無い（要件 MU-01〜MU-04）。
class MuteService
  class CannotMuteSelf < StandardError; end

  def self.mute!(muter:, muted:)
    raise CannotMuteSelf if muter == muted

    Mute.find_or_create_by!(muter: muter, muted: muted)
  end

  def self.unmute!(muter:, muted:)
    Mute.where(muter: muter, muted: muted).destroy_all
  end
end
