'use client';

import { useState, type FormEvent } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { Search as SearchIcon } from 'lucide-react';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { PostCard } from '@/components/PostCard';
import { searchAll } from '@/lib/api/search';

export default function SearchPage() {
  const [query, setQuery] = useState('');
  const [submitted, setSubmitted] = useState('');

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setSubmitted(query.trim());
  }

  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <form
          onSubmit={handleSubmit}
          className="border-b border-slate-200 bg-white px-4 py-3 dark:border-slate-800 dark:bg-slate-900"
        >
          <div className="flex items-center gap-2 rounded-full border border-slate-300 bg-white px-3 py-1.5 dark:border-slate-700 dark:bg-slate-800">
            <SearchIcon className="size-4 text-slate-400" />
            <input
              type="search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="ユーザー / 本 / 投稿 / タグ を検索"
              className="flex-1 bg-transparent text-sm focus:outline-none"
            />
          </div>
        </form>
        {submitted ? <Results q={submitted} /> : <Hint />}
      </main>
    </AuthGuard>
  );
}

function Hint() {
  return (
    <p className="py-8 text-center text-sm text-slate-500">
      キーワードを入力して Enter で検索
    </p>
  );
}

function Results({ q }: { q: string }) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['search', q],
    queryFn: () => searchAll(q),
  });

  if (isLoading) return <p className="py-8 text-center text-sm text-slate-500">検索中…</p>;
  if (isError) return <p className="py-8 text-center text-sm text-red-600">検索に失敗しました</p>;

  const result = data?.data ?? {};
  const empty =
    (result.users?.length ?? 0) === 0 &&
    (result.books?.length ?? 0) === 0 &&
    (result.posts?.length ?? 0) === 0 &&
    (result.tags?.length ?? 0) === 0;

  if (empty) return <p className="py-8 text-center text-sm text-slate-500">該当する結果がありません</p>;

  return (
    <div>
      {result.users && result.users.length > 0 && (
        <Section title="ユーザー">
          {result.users.map((u) => {
            const a = u.attributes;
            return (
              <Link
                key={u.id}
                href={`/users/${a.handle}`}
                className="block border-b border-slate-200 bg-white px-4 py-3 hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800"
              >
                <p className="font-medium">{a.display_name}</p>
                <p className="text-sm text-slate-500">@{a.handle}</p>
              </Link>
            );
          })}
        </Section>
      )}

      {result.books && result.books.length > 0 && (
        <Section title="本">
          {result.books.map((b) => (
            <div
              key={b.id}
              className="border-b border-slate-200 bg-white px-4 py-3 dark:border-slate-800 dark:bg-slate-900"
            >
              <p className="font-medium">{b.attributes.title}</p>
              <p className="text-sm text-slate-500">{b.attributes.author}</p>
            </div>
          ))}
        </Section>
      )}

      {result.posts && result.posts.length > 0 && (
        <Section title="投稿">
          {result.posts.map((p) => (
            <PostCard key={p.id} post={p} />
          ))}
        </Section>
      )}

      {result.tags && result.tags.length > 0 && (
        <Section title="タグ">
          {result.tags.map((t) => (
            <Link
              key={t.id}
              href={`/hashtags/${encodeURIComponent(t.attributes.name)}`}
              className="block border-b border-slate-200 bg-white px-4 py-3 hover:bg-slate-50 dark:border-slate-800 dark:bg-slate-900 dark:hover:bg-slate-800"
            >
              <p className="font-medium text-blue-600 dark:text-blue-400">
                #{t.attributes.name}
              </p>
              <p className="text-xs text-slate-500">{t.attributes.counts.posts} 投稿</p>
            </Link>
          ))}
        </Section>
      )}
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <h2 className="border-b border-slate-200 bg-slate-50 px-4 py-2 text-xs font-semibold uppercase text-slate-500 dark:border-slate-800 dark:bg-slate-900/50 dark:text-slate-400">
        {title}
      </h2>
      {children}
    </section>
  );
}
