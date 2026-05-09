'use client';

import { useState, type FormEvent } from 'react';
import { useQueryClient } from '@tanstack/react-query';
import { createPost } from '@/lib/api/posts';

const MAX = 500;

export function PostComposer() {
  const queryClient = useQueryClient();
  const [body, setBody] = useState('');
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy || body.trim().length === 0) return;
    setError(null);
    setBusy(true);
    try {
      await createPost(body.trim());
      setBody('');
      queryClient.invalidateQueries({ queryKey: ['timeline'] });
    } catch {
      setError('投稿に失敗しました');
    } finally {
      setBusy(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="border-b border-slate-200 bg-white px-4 py-3 dark:border-slate-800 dark:bg-slate-900"
    >
      <textarea
        value={body}
        onChange={(e) => setBody(e.target.value)}
        rows={3}
        maxLength={MAX}
        placeholder="読書感想を書く…（#タグ も使えます）"
        className="w-full resize-none border-0 bg-transparent text-sm focus:outline-none"
      />
      {error && <p className="text-sm text-red-600">{error}</p>}
      <div className="mt-1 flex items-center justify-between text-xs text-slate-500">
        <span>残り {MAX - body.length} 文字</span>
        <button
          type="submit"
          disabled={busy || body.trim().length === 0}
          className="rounded-full bg-slate-900 px-4 py-1.5 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-slate-50 dark:text-slate-900 dark:hover:bg-slate-200"
        >
          {busy ? '投稿中…' : '投稿'}
        </button>
      </div>
    </form>
  );
}
