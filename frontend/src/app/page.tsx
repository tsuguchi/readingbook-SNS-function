'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/auth/AuthProvider';

export default function Home() {
  const auth = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (auth.status === 'authenticated') router.replace('/home');
    else if (auth.status === 'anonymous') router.replace('/login');
  }, [auth.status, router]);

  return (
    <div className="flex min-h-dvh items-center justify-center">
      <p className="text-sm text-slate-500">読み込み中…</p>
    </div>
  );
}
