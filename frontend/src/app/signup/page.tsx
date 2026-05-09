'use client';

import { useState, type FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { signup } from '@/lib/api/auth';
import { useAuth } from '@/lib/auth/AuthProvider';

export default function SignupPage() {
  const router = useRouter();
  const { setUser } = useAuth();
  const [form, setForm] = useState({ email: '', password: '', handle: '', display_name: '' });
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const { data } = await signup(form);
      setUser(data);
      router.replace('/home');
    } catch (e: unknown) {
      console.error('signup error:', e);
      try {
        const httpError = e as { response?: Response };
        if (httpError.response) {
          const body = (await httpError.response.json()) as { error?: { message?: string } };
          setError(body.error?.message ?? '登録に失敗しました');
        } else {
          setError(`登録に失敗しました: ${(e as Error)?.message ?? 'unknown'}`);
        }
      } catch {
        setError('登録に失敗しました');
      }
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-dvh items-center justify-center px-4 py-8">
      <div className="w-full max-w-sm rounded-xl border border-slate-200 bg-white p-8 shadow-sm dark:border-slate-800 dark:bg-slate-900">
        <h1 className="mb-1 text-center text-2xl font-bold tracking-tight">読書 SNS</h1>
        <p className="mb-6 text-center text-sm text-slate-500">新規アカウント作成</p>

        <form onSubmit={handleSubmit} className="space-y-4">
          <Field
            label="メールアドレス"
            type="email"
            value={form.email}
            onChange={(v) => setForm((f) => ({ ...f, email: v }))}
          />
          <Field
            label="パスワード（6 文字以上）"
            type="password"
            minLength={6}
            value={form.password}
            onChange={(v) => setForm((f) => ({ ...f, password: v }))}
          />
          <Field
            label="ユーザー名（@ハンドル）"
            type="text"
            pattern="[A-Za-z0-9_]{3,20}"
            value={form.handle}
            onChange={(v) => setForm((f) => ({ ...f, handle: v }))}
            hint="3〜20 文字、半角英数字とアンダースコア"
          />
          <Field
            label="表示名"
            type="text"
            value={form.display_name}
            onChange={(v) => setForm((f) => ({ ...f, display_name: v }))}
          />

          {error && <p className="text-sm text-red-600">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full rounded-md bg-slate-900 py-2 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-slate-50 dark:text-slate-900 dark:hover:bg-slate-200"
          >
            {loading ? '登録中…' : 'アカウント作成'}
          </button>
        </form>

        <p className="mt-6 text-center text-sm text-slate-500">
          すでにアカウントをお持ちの方は{' '}
          <Link href="/login" className="text-slate-900 underline dark:text-slate-50">
            ログイン
          </Link>
        </p>
      </div>
    </main>
  );
}

function Field({
  label,
  hint,
  value,
  onChange,
  ...rest
}: {
  label: string;
  hint?: string;
  value: string;
  onChange: (value: string) => void;
} & Omit<React.InputHTMLAttributes<HTMLInputElement>, 'value' | 'onChange'>) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-medium">{label}</span>
      <input
        required
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-slate-900 focus:outline-none dark:border-slate-700 dark:bg-slate-800"
        {...rest}
      />
      {hint && <span className="mt-1 block text-xs text-slate-500">{hint}</span>}
    </label>
  );
}
