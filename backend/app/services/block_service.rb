# ブロックの作成・解除を扱うサービス。
# ブロック成立時は要件 BL-02 に従って双方のフォロー関係を解除する。
# また、ブロック関係にあるユーザー間のいいねも要件 LK-08 整合のため削除する。
class BlockService
  class CannotBlockSelf < StandardError; end

  def self.block!(blocker:, blocked:)
    raise CannotBlockSelf if blocker == blocked

    ActiveRecord::Base.transaction do
      block = Block.find_or_create_by!(blocker: blocker, blocked: blocked)
      cleanup_relations!(blocker, blocked)
      block
    end
  end

  def self.unblock!(blocker:, blocked:)
    Block.where(blocker: blocker, blocked: blocked).destroy_all
  end

  # ブロック成立時のクリーンアップ:
  #   - 双方のフォロー関係を解除（BL-02）
  #   - 双方のいいねを削除（LK-08 と整合）
  # 通知は明示的に送らない（BL-05）
  def self.cleanup_relations!(blocker, blocked)
    # 双方向フォロー解除
    Follow.where(follower_id: [ blocker.id, blocked.id ],
                 followee_id: [ blocker.id, blocked.id ]).destroy_all

    # 互いのコンテンツに対するいいねを削除
    target_post_ids = Post.where(user_id: [ blocker.id, blocked.id ]).pluck(:id)
    target_comment_ids = Comment.where(user_id: [ blocker.id, blocked.id ]).pluck(:id)

    Like.where(user_id: [ blocker.id, blocked.id ])
        .where("(target_type = 'Post' AND target_id IN (?)) OR " \
               "(target_type = 'Comment' AND target_id IN (?))",
               target_post_ids, target_comment_ids)
        .destroy_all
  end
  private_class_method :cleanup_relations!
end
