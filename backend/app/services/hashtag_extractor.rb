# 投稿本文から #ハッシュタグ を抽出して Hashtag レコードと関連付けるサービス。
# 半角 # / 全角 ＃ どちらも受け付けるが、永続化時は半角に正規化する。
class HashtagExtractor
  # 半角 # または全角 ＃ の後に続く、空白でない 1〜100 文字のシーケンスを抽出。
  # アスキー以外（日本語）も含めるため [^\s#＃] で広めに取る。
  HASHTAG_REGEX = /[#＃]([^\s#＃]{1,100})/

  def self.extract_names(body)
    return [] if body.blank?

    body.to_s.scan(HASHTAG_REGEX).flatten.map(&:strip).reject(&:blank?).uniq
  end

  # post.body から抽出したタグで post.hashtags を上書きする。
  # 既存タグがあれば再利用、なければ作成。
  def self.sync!(post)
    names = extract_names(post.body)
    hashtags = names.map { |name| Hashtag.find_or_create_by!(name: name) }
    post.hashtags = hashtags
  end
end
