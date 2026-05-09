'use client';

import Link from 'next/link';
import { MessageCircle, Repeat2 } from 'lucide-react';
import { LikeButton } from './LikeButton';
import type { PostResource } from '@/lib/api/types';

function formatDate(iso: string): string {
  const d = new Date(iso);
  return d.toLocaleString('ja-JP', { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export function PostCard({ post }: { post: PostResource }) {
  const a = post.attributes;
  const user = a.user.attributes;

  return (
    <article className="border-b border-slate-200 bg-white px-4 py-4 dark:border-slate-800 dark:bg-slate-900">
      <div className="flex items-baseline gap-2">
        <Link href={`/users/${user.handle}`} className="font-semibold hover:underline">
          {user.display_name}
        </Link>
        <span className="text-sm text-slate-500">@{user.handle}</span>
        <span className="ml-auto text-xs text-slate-400">{formatDate(a.created_at)}</span>
      </div>

      <p className="mt-2 whitespace-pre-wrap break-words leading-relaxed">{a.body}</p>

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

      <div className="mt-3 flex items-center gap-4 text-slate-500">
        <Link
          href={`/posts/${post.id}`}
          className="flex items-center gap-1 rounded-full px-2 py-1 text-sm hover:bg-slate-100 dark:hover:bg-slate-800"
        >
          <MessageCircle className="size-4" />
          <span>{a.counts.comments}</span>
        </Link>
        <span className="flex items-center gap-1 rounded-full px-2 py-1 text-sm">
          <Repeat2 className="size-4" />
          <span>{a.counts.reposts}</span>
        </span>
        <LikeButton postId={post.id} initialLiked={a.is_liked} initialCount={a.counts.likes} />
      </div>
    </article>
  );
}
