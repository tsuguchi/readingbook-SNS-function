'use client';

import { useQuery } from '@tanstack/react-query';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { PostCard } from '@/components/PostCard';
import { fetchExploreTimeline } from '@/lib/api/posts';

export default function ExplorePage() {
  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <h1 className="border-b border-slate-200 bg-white px-4 py-3 text-base font-semibold dark:border-slate-800 dark:bg-slate-900">
          探索
        </h1>
        <ExploreTimeline />
      </main>
    </AuthGuard>
  );
}

function ExploreTimeline() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['timeline', 'explore'],
    queryFn: fetchExploreTimeline,
  });

  if (isLoading) return <p className="py-8 text-center text-sm text-slate-500">読み込み中…</p>;
  if (isError) return <p className="py-8 text-center text-sm text-red-600">取得に失敗しました</p>;

  const posts = data?.data ?? [];
  if (posts.length === 0) {
    return <p className="py-8 text-center text-sm text-slate-500">公開アカウントの投稿がまだありません</p>;
  }

  return (
    <div>
      {posts.map((p) => (
        <PostCard key={p.id} post={p} />
      ))}
    </div>
  );
}
