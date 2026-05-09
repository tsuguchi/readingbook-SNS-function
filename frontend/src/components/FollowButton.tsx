'use client';

import { useState } from 'react';
import { followUser, unfollowUser } from '@/lib/api/users';

type Props = {
  handle: string;
  initialFollowing: boolean;
  initialPending?: boolean;
};

export function FollowButton({ handle, initialFollowing, initialPending }: Props) {
  const [following, setFollowing] = useState(initialFollowing);
  const [pending, setPending] = useState(initialPending ?? false);
  const [busy, setBusy] = useState(false);

  async function toggle() {
    if (busy) return;
    setBusy(true);
    try {
      if (following || pending) {
        await unfollowUser(handle);
        setFollowing(false);
        setPending(false);
      } else {
        const res = await followUser(handle);
        if (res.data.status === 'accepted') setFollowing(true);
        else setPending(true);
      }
    } finally {
      setBusy(false);
    }
  }

  let label = 'フォロー';
  let className = 'bg-slate-900 text-white hover:bg-slate-700 dark:bg-slate-50 dark:text-slate-900';
  if (following) {
    label = 'フォロー中';
    className = 'border border-slate-300 text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200';
  } else if (pending) {
    label = '申請中';
    className = 'border border-slate-300 text-slate-500';
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={busy}
      className={`rounded-full px-4 py-1.5 text-sm font-medium transition disabled:cursor-not-allowed disabled:opacity-50 ${className}`}
    >
      {label}
    </button>
  );
}
