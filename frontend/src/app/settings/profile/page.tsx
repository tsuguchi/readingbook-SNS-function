'use client';

import { useState, type FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import { AppHeader } from '@/components/AppHeader';
import { AuthGuard } from '@/components/AuthGuard';
import { useAuth } from '@/lib/auth/AuthProvider';
import { updateProfile } from '@/lib/api/me';

export default function ProfileEditPage() {
  return (
    <AuthGuard>
      <AppHeader />
      <main className="mx-auto max-w-2xl">
        <div className="border-b border-slate-200 bg-white px-4 py-2 dark:border-slate-800 dark:bg-slate-900">
          <Link
            href="/home"
            className="flex items-center gap-1 text-sm text-slate-600 hover:underline dark:text-slate-400"
          >
            <ArrowLeft className="size-4" /> 戻る
          </Link>
        </div>
        <Form />
      </main>
    </AuthGuard>
  );
}

function Form() {
  const auth = useAuth();
  if (auth.status !== 'authenticated') return null;
  // key を渡すことで初期値の useState が現在のユーザー情報で初期化される
  return <FormInner key={auth.user.id} />;
}

function FormInner() {
  const auth = useAuth();
  const router = useRouter();
  // 親 Form で認証チェック済み。ここに来た時点で必ず authenticated。
  const me = auth.status === 'authenticated' ? auth.user.attributes : null;

  const [displayName, setDisplayName] = useState(me?.display_name ?? '');
  const [bio, setBio] = useState(me?.bio ?? '');
  const [isPrivate, setIsPrivate] = useState(me?.is_private ?? false);
  const [readingGoal, setReadingGoal] = useState<string>(
    me?.reading_goal !== null && me?.reading_goal !== undefined ? String(me.reading_goal) : '',
  );
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (auth.status !== 'authenticated') return null;

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (busy) return;
    setBusy(true);
    setError(null);
    setDone(false);
    try {
      const res = await updateProfile({
        display_name: displayName,
        bio,
        is_private: isPrivate,
        reading_goal: readingGoal === '' ? null : Number(readingGoal),
      });
      auth.setUser(res.data);
      setDone(true);
      setTimeout(() => router.push(`/users/${res.data.attributes.handle}`), 600);
    } catch (e: unknown) {
      const msg =
        typeof e === 'object' && e !== null && 'message' in e
          ? String((e as { message: string }).message)
          : '更新に失敗しました';
      setError(msg);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      className="space-y-5 border-b border-slate-200 bg-white px-4 py-6 dark:border-slate-800 dark:bg-slate-900"
    >
      <h1 className="text-lg font-semibold">プロフィール編集</h1>

      <Field label="表示名">
        <input
          type="text"
          maxLength={50}
          required
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
          className="w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-slate-900 focus:outline-none dark:border-slate-700 dark:bg-slate-800"
        />
      </Field>

      <Field label="自己紹介（200 文字まで）">
        <textarea
          rows={3}
          maxLength={200}
          value={bio}
          onChange={(e) => setBio(e.target.value)}
          className="w-full resize-none rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-slate-900 focus:outline-none dark:border-slate-700 dark:bg-slate-800"
        />
      </Field>

      <Field label="読書目標（年間冊数）">
        <input
          type="number"
          min={0}
          value={readingGoal}
          onChange={(e) => setReadingGoal(e.target.value)}
          className="w-32 rounded-md border border-slate-300 bg-white px-3 py-2 text-sm focus:border-slate-900 focus:outline-none dark:border-slate-700 dark:bg-slate-800"
        />
      </Field>

      <label className="flex items-center gap-2 text-sm">
        <input
          type="checkbox"
          checked={isPrivate}
          onChange={(e) => setIsPrivate(e.target.checked)}
          className="size-4"
        />
        非公開アカウント（フォローには承認が必要になる）
      </label>

      {error && <p className="text-sm text-red-600">{error}</p>}
      {done && <p className="text-sm text-green-600">保存しました</p>}

      <button
        type="submit"
        disabled={busy}
        className="rounded-full bg-slate-900 px-5 py-2 text-sm font-medium text-white transition hover:bg-slate-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-slate-50 dark:text-slate-900 dark:hover:bg-slate-200"
      >
        {busy ? '保存中…' : '保存'}
      </button>
    </form>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1 block text-sm font-medium">{label}</span>
      {children}
    </label>
  );
}
