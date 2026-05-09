'use client';

import { useState } from 'react';
import { Heart } from 'lucide-react';
import { likePost, unlikePost } from '@/lib/api/posts';

type Props = {
  postId: string;
  initialLiked: boolean;
  initialCount: number;
};

// 楽観的 UI でいいねをトグル。失敗時は元の状態に戻す。
export function LikeButton({ postId, initialLiked, initialCount }: Props) {
  const [liked, setLiked] = useState(initialLiked);
  const [count, setCount] = useState(initialCount);
  const [busy, setBusy] = useState(false);

  async function toggle() {
    if (busy) return;
    setBusy(true);

    const wasLiked = liked;
    const wasCount = count;

    // 楽観的更新
    setLiked(!wasLiked);
    setCount(wasLiked ? Math.max(0, wasCount - 1) : wasCount + 1);

    try {
      const res = wasLiked ? await unlikePost(postId) : await likePost(postId);
      // サーバの真の値で上書き（揺らぎ吸収）
      setLiked(res.data.is_liked);
      setCount(res.data.likes_count);
    } catch {
      setLiked(wasLiked);
      setCount(wasCount);
    } finally {
      setBusy(false);
    }
  }

  return (
    <button
      type="button"
      onClick={toggle}
      aria-pressed={liked}
      aria-label={liked ? 'いいねを取り消す' : 'いいねする'}
      className={`group flex items-center gap-1 rounded-full px-2 py-1 text-sm transition ${
        liked ? 'text-rose-600' : 'text-slate-500'
      } hover:bg-rose-50 dark:hover:bg-rose-950/20`}
    >
      <Heart className={`size-4 transition-transform ${liked ? 'fill-rose-600' : ''}`} />
      <span>{count}</span>
    </button>
  );
}
