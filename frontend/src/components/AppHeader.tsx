'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthProvider';
import { Bell, Compass, Home, LogOut, Search, User as UserIcon } from 'lucide-react';

export function AppHeader() {
  const auth = useAuth();
  const router = useRouter();

  if (auth.status !== 'authenticated') return null;
  const { user, logout } = auth;

  async function handleLogout() {
    await logout();
    router.replace('/login');
  }

  return (
    <header className="sticky top-0 z-10 border-b border-slate-200 bg-white/80 backdrop-blur dark:border-slate-800 dark:bg-slate-950/80">
      <div className="mx-auto flex h-14 max-w-2xl items-center gap-4 px-4">
        <Link href="/home" className="font-bold tracking-tight">
          読書 SNS
        </Link>
        <nav className="ml-auto flex items-center gap-1 text-slate-600 dark:text-slate-400">
          <Link href="/home" aria-label="ホーム" className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
            <Home className="size-5" />
          </Link>
          <Link href="/explore" aria-label="探索" className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
            <Compass className="size-5" />
          </Link>
          <Link href="/search" aria-label="検索" className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
            <Search className="size-5" />
          </Link>
          <Link href="/notifications" aria-label="通知" className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800">
            <Bell className="size-5" />
          </Link>
          <Link
            href={`/users/${user.attributes.handle}`}
            aria-label="プロフィール"
            className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <UserIcon className="size-5" />
          </Link>
          <button
            onClick={handleLogout}
            aria-label="ログアウト"
            className="rounded-full p-2 hover:bg-slate-100 dark:hover:bg-slate-800"
          >
            <LogOut className="size-5" />
          </button>
        </nav>
      </div>
    </header>
  );
}
