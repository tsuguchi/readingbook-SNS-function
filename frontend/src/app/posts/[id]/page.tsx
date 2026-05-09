'use client';

import { use, useState, type FormEvent } from 'react';
import Link from 'next/link';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft } from 'lucide-react';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { LikeButton } from '@/components/LikeButton';
import { fetchPost, fetchComments, createComment } from '@/lib/api/posts';
import type { CommentResource } from '@/lib/api/types';

export default function PostDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <BackBar />
        <PostDetail id={id} />
        <CommentList postId={id} />
        <CommentForm postId={id} />
      </main>
    </AuthGuard>
  );
}

function BackBar() {
  return (
    <div className="border-b border-slate-200 bg-white px-4 py-2 dark:border-slate-800 dark:bg-slate-900">
      <Link href="/home" className="flex items-center gap-1 text-sm text-slate-600 hover:underline dark:text-slate-400">
        <ArrowLeft className="size-4" /> 戻る
      </Link>
    </div>
  );
}

function PostDetail({ id }: { id: string }) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['post', id],
    queryFn: () => fetchPost(id),
  });

  if (isLoading) return <p className="py-8 text-center text-sm text-slate-500">読み込み中…</p>;
  if (isError || !data) return <p className="py-8 text-center text-sm text-red-600">投稿が見つかりません</p>;

  const post = data.data;
  const a = post.attributes;
  const user = a.user.attributes;

  return (
    <article className="border-b border-slate-200 bg-white px-4 py-6 dark:border-slate-800 dark:bg-slate-900">
      <div className="flex items-baseline gap-2">
        <Link href={`/users/${user.handle}`} className="font-semibold hover:underline">
          {user.display_name}
        </Link>
        <span className="text-sm text-slate-500">@{user.handle}</span>
      </div>
      <p className="mt-3 whitespace-pre-wrap break-words text-base leading-relaxed">{a.body}</p>
      {a.book && (
        <div className="mt-3 rounded-md border border-slate-200 px-3 py-2 text-sm dark:border-slate-800">
          <span className="text-slate-500">📖 </span>
          <span className="font-medium">{a.book.attributes.title}</span>
          {a.book.attributes.author && (
            <span className="ml-2 text-slate-500">{a.book.attributes.author}</span>
          )}
        </div>
      )}
      {a.hashtags.length > 0 && (
        <div className="mt-2 flex flex-wrap gap-2">
          {a.hashtags.map((tag) => (
            <Link
              key={tag}
              href={`/hashtags/${encodeURIComponent(tag)}`}
              className="text-sm text-blue-600 hover:underline dark:text-blue-400"
            >
              #{tag}
            </Link>
          ))}
        </div>
      )}
      <p className="mt-3 text-xs text-slate-400">{new Date(a.created_at).toLocaleString('ja-JP')}</p>
      <div className="mt-3 border-t border-slate-100 pt-3 dark:border-slate-800">
        <LikeButton postId={post.id} initialLiked={a.is_liked} initialCount={a.counts.likes} />
      </div>
    </article>
  );
}

function CommentList({ postId }: { postId: string }) {
  const { data, isLoading } = useQuery({
    queryKey: ['comments', postId],
    queryFn: () => fetchComments(postId),
  });

  if (isLoading) return <p className="py-4 text-center text-sm text-slate-500">読み込み中…</p>;
  const comments = data?.data ?? [];

  if (comments.length === 0) {
    return <p className="px-4 py-4 text-sm text-slate-500">コメントはまだありません</p>;
  }

  return (
    <div>
      {comments.map((c) => (
        <CommentItem key={c.id} comment={c} />
      ))}
    </div>
  );
}

function CommentItem({ comment }: { comment: CommentResource }) {
  const a = comment.attributes;
  const user = a.user.attributes;
  return (
    <div className="border-b border-slate-200 bg-white px-4 py-3 dark:border-slate-800 dark:bg-slate-900">
      <div className="flex items-baseline gap-2">
        <Link href={`/users/${user.handle}`} className="text-sm font-semibold hover:underline">
          {user.display_name}
        </Link>
        <span className="text-xs text-slate-500">@{user.handle}</span>
        <span className="ml-auto text-xs text-slate-400">
          {new Date(a.created_at).toLocaleString('ja-JP')}
        </span>
      </div>
      <p className="mt-1 whitespace-pre-wrap break-words text-sm">{a.body}</p>
    </div>
  );
}

function CommentForm({ postId }: { postId: string }) {
  const queryClient = useQueryClient();
  const [body, setBody] = useState('');
  const [busy, setBusy] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy || body.trim().length === 0) return;
    setBusy(true);
    try {
      await createComment(postId, body.trim());
      setBody('');
      queryClient.invalidateQueries({ queryKey: ['comments', postId] });
      queryClient.invalidateQueries({ queryKey: ['post', postId] });
    } finally {
      setBusy(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="sticky bottom-0 border-t border-slate-200 bg-white px-4 py-3 dark:border-slate-800 dark:bg-slate-900"
    >
      <div className="flex items-center gap-2">
        <input
          type="text"
          value={body}
          onChange={(e) => setBody(e.target.value)}
          maxLength={500}
          placeholder="コメントを書く…"
          className="flex-1 rounded-full border border-slate-300 bg-white px-3 py-1.5 text-sm focus:border-slate-900 focus:outline-none dark:border-slate-700 dark:bg-slate-800"
        />
        <button
          type="submit"
          disabled={busy || body.trim().length === 0}
          className="rounded-full bg-slate-900 px-4 py-1.5 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-slate-50 dark:text-slate-900 dark:hover:bg-slate-200"
        >
          送信
        </button>
      </div>
    </form>
  );
}
