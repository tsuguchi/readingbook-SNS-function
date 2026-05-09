'use client';

import { use } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { PostCard } from '@/components/PostCard';
import { fetchUser, fetchUserPosts } from '@/lib/api/users';
import { useAuth } from '@/lib/auth/AuthProvider';
import { FollowButton } from '@/components/FollowButton';

export default function UserProfilePage({ params }: { params: Promise<{ handle: string }> }) {
  // Next.js 15+ で params は Promise になった
  const { handle } = use(params);
  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <Profile handle={handle} />
        <UserPosts handle={handle} />
      </main>
    </AuthGuard>
  );
}

function Profile({ handle }: { handle: string }) {
  const auth = useAuth();
  const { data, isLoading, isError } = useQuery({
    queryKey: ['user', handle],
    queryFn: () => fetchUser(handle),
  });

  if (isLoading) return <Block>読み込み中…</Block>;
  if (isError || !data) return <Block error>ユーザーが見つかりません</Block>;

  const user = data.data.attributes;
  const isMe = auth.status === 'authenticated' && auth.user.id === data.data.id;

  return (
    <section className="border-b border-slate-200 bg-white px-4 py-6 dark:border-slate-800 dark:bg-slate-900">
      <div className="flex items-start gap-4">
        <div className="flex size-16 items-center justify-center rounded-full bg-slate-200 text-2xl font-bold text-slate-600 dark:bg-slate-700 dark:text-slate-300">
          {user.display_name.slice(0, 1)}
        </div>
        <div className="flex-1">
          <h1 className="text-xl font-bold tracking-tight">{user.display_name}</h1>
          <p className="text-sm text-slate-500">
            @{user.handle}
            {user.is_private && <span className="ml-2 text-xs">🔒 非公開</span>}
          </p>
          {user.bio && <p className="mt-2 text-sm leading-relaxed">{user.bio}</p>}
          <p className="mt-3 text-sm text-slate-600 dark:text-slate-400">
            <strong>{user.counts.posts}</strong> 投稿 ・{' '}
            <strong>{user.counts.followers}</strong> フォロワー ・{' '}
            <strong>{user.counts.following}</strong> フォロー中
          </p>
        </div>
        {isMe ? (
          <Link
            href="/settings/profile"
            className="rounded-full border border-slate-300 px-4 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200"
          >
            プロフィール編集
          </Link>
        ) : (
          <FollowButton handle={handle} initialFollowing={false} />
        )}
      </div>
    </section>
  );
}

function UserPosts({ handle }: { handle: string }) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['user-posts', handle],
    queryFn: () => fetchUserPosts(handle),
  });

  if (isLoading) return <Block>読み込み中…</Block>;
  if (isError) return <Block error>投稿の取得に失敗しました</Block>;

  const posts = data?.data ?? [];
  if (posts.length === 0) return <Block>まだ投稿がありません</Block>;

  return (
    <div>
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
}

function Block({ children, error }: { children: React.ReactNode; error?: boolean }) {
  return (
    <p className={`py-8 text-center text-sm ${error ? 'text-red-600' : 'text-slate-500'}`}>
      {children}
    </p>
  );
}
