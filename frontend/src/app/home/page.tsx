'use client';

import { useQuery } from '@tanstack/react-query';
import { fetchHomeTimeline } from '@/lib/api/posts';
import { PostCard } from '@/components/PostCard';
import { PostComposer } from '@/components/PostComposer';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';

export default function HomePage() {
  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <PostComposer />
        <Timeline />
      </main>
    </AuthGuard>
  );
}

function Timeline() {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['timeline', 'home'],
    queryFn: fetchHomeTimeline,
  });

  if (isLoading) {
    return <p className="py-8 text-center text-sm text-slate-500">読み込み中…</p>;
  }
  if (isError) {
    return <p className="py-8 text-center text-sm text-red-600">タイムラインの取得に失敗しました</p>;
  }

  const posts = data?.data ?? [];
  if (posts.length === 0) {
    return (
      <div className="px-4 py-12 text-center text-sm text-slate-500">
        <p>📚 まだ投稿がありません</p>
        <p className="mt-2">ユーザーをフォローしてタイムラインを充実させましょう</p>
      </div>
    );
  }

  return (
    <div>
      {posts.map((post) => (
        <PostCard key={post.id} post={post} />
      ))}
    </div>
  );
}
