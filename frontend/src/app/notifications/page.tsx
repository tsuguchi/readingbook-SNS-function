'use client';

import Link from 'next/link';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';
import {
  fetchNotifications,
  markAllNotificationsRead,
  type NotificationResource,
} from '@/lib/api/notifications';

export default function NotificationsPage() {
  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <Header />
        <NotificationList />
      </main>
    </AuthGuard>
  );
}

function Header() {
  const queryClient = useQueryClient();

  async function readAll() {
    await markAllNotificationsRead();
    queryClient.invalidateQueries({ queryKey: ['notifications'] });
  }

  return (
    <div className="flex items-center justify-between border-b border-slate-200 bg-white px-4 py-3 dark:border-slate-800 dark:bg-slate-900">
      <h1 className="text-base font-semibold">通知</h1>
      <button
        type="button"
        onClick={readAll}
        className="text-xs text-slate-600 hover:underline dark:text-slate-400"
      >
        すべて既読
      </button>
    </div>
  );
}

function NotificationList() {
  const { data, isLoading } = useQuery({
    queryKey: ['notifications'],
    queryFn: () => fetchNotifications(),
  });

  if (isLoading) return <p className="py-8 text-center text-sm text-slate-500">読み込み中…</p>;
  const items = data?.data ?? [];
  if (items.length === 0) {
    return <p className="py-8 text-center text-sm text-slate-500">🔔 まだ通知はありません</p>;
  }

  return (
    <div>
      {items.map((n) => (
        <NotificationItem key={n.id} notification={n} />
      ))}
    </div>
  );
}

function NotificationItem({ notification }: { notification: NotificationResource }) {
  const a = notification.attributes;
  const actor = a.actor.attributes;
  const isUnread = a.read_at === null;

  return (
    <div
      className={`border-b border-slate-200 px-4 py-3 dark:border-slate-800 ${
        isUnread ? 'bg-blue-50 dark:bg-blue-950/30' : 'bg-white dark:bg-slate-900'
      }`}
    >
      <div className="flex items-start gap-3">
        <div className="flex size-8 items-center justify-center rounded-full bg-slate-200 text-sm font-bold text-slate-600 dark:bg-slate-700 dark:text-slate-300">
          {actor.display_name.slice(0, 1)}
        </div>
        <div className="flex-1 text-sm">
          <p>
            <Link href={`/users/${actor.handle}`} className="font-semibold hover:underline">
              {actor.display_name}
            </Link>{' '}
            {labelFor(a.notification_type)}
          </p>
          {a.target && 'attributes' in a.target && 'body' in a.target.attributes && (
            <Link
              href={`/posts/${a.target.id}`}
              className="mt-1 line-clamp-2 block text-xs text-slate-600 hover:underline dark:text-slate-400"
            >
              {(a.target.attributes as { body: string }).body}
            </Link>
          )}
          <span className="mt-1 block text-xs text-slate-400">
            {new Date(a.created_at).toLocaleString('ja-JP')}
          </span>
        </div>
      </div>
    </div>
  );
}

function labelFor(type: string): string {
  switch (type) {
    case 'like_post':
      return 'があなたの投稿にいいねしました';
    case 'like_comment':
      return 'があなたのコメントにいいねしました';
    case 'follow':
      return 'があなたをフォローしました';
    case 'follow_request':
      return 'からフォローリクエストが届きました';
    case 'follow_accepted':
      return 'があなたのフォローを承認しました';
    case 'repost':
      return 'があなたの投稿をリポストしました';
    case 'quote_repost':
      return 'があなたの投稿を引用リポストしました';
    case 'comment':
      return 'があなたの投稿にコメントしました';
    default:
      return 'からの通知';
  }
}
