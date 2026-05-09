'use client';

import { createContext, useContext, useEffect, useState, type ReactNode } from 'react';
import { fetchMe, logout as apiLogout } from '../api/auth';
import { getToken, setToken } from '../api/client';
import type { UserResource } from '../api/types';

type AuthState =
  | { status: 'loading' }
  | { status: 'authenticated'; user: UserResource }
  | { status: 'anonymous' };

type AuthContextValue = AuthState & {
  refresh: () => Promise<void>;
  logout: () => Promise<void>;
  setUser: (user: UserResource) => void;
};

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<AuthState>({ status: 'loading' });

  const refresh = async () => {
    if (!getToken()) {
      setState({ status: 'anonymous' });
      return;
    }
    try {
      const { data } = await fetchMe();
      setState({ status: 'authenticated', user: data });
    } catch {
      // トークン期限切れなどで失敗したらゲストに戻す
      setToken(null);
      setState({ status: 'anonymous' });
    }
  };

  // 初回マウントで保存済みトークンの妥当性を /me で検証する。
  // ここは外部システム（localStorage / API）との同期が目的のため
  // setState in effect の警告を意図的に抑制する。
  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    void refresh();
  }, []);

  const logout = async () => {
    await apiLogout();
    setState({ status: 'anonymous' });
  };

  const setUser = (user: UserResource) => setState({ status: 'authenticated', user });

  return (
    <AuthContext.Provider value={{ ...state, refresh, logout, setUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
