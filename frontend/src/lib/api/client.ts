// シンプルな fetch ベースの API クライアント。
// すべてのリクエストに Authorization: Bearer <jwt> を自動付与する。
//
// レスポンスがエラー（4xx/5xx）の場合は ApiError を throw する。
// 呼び出し側は try-catch で扱う。

const API_BASE = process.env.NEXT_PUBLIC_API_BASE ?? 'http://localhost:3001/api/v1';
const TOKEN_KEY = 'readingbook_jwt';

export function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return window.localStorage.getItem(TOKEN_KEY);
}

export function setToken(token: string | null) {
  if (typeof window === 'undefined') return;
  if (token) window.localStorage.setItem(TOKEN_KEY, token);
  else window.localStorage.removeItem(TOKEN_KEY);
}

export class ApiError extends Error {
  status: number;
  body: unknown;
  constructor(status: number, body: unknown, message: string) {
    super(message);
    this.status = status;
    this.body = body;
  }
}

type RequestOptions = {
  method?: string;
  json?: unknown;
  query?: Record<string, string | number | undefined>;
};

async function request<T>(path: string, options: RequestOptions = {}): Promise<{
  data: T;
  authHeader: string | null;
}> {
  const headers: Record<string, string> = {
    Accept: 'application/json',
  };
  if (options.json !== undefined) headers['Content-Type'] = 'application/json';
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  let url = `${API_BASE}/${path.replace(/^\//, '')}`;
  if (options.query) {
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(options.query)) {
      if (value !== undefined && value !== null && value !== '') {
        params.set(key, String(value));
      }
    }
    const qs = params.toString();
    if (qs) url += `?${qs}`;
  }

  const response = await fetch(url, {
    method: options.method ?? 'GET',
    headers,
    body: options.json !== undefined ? JSON.stringify(options.json) : undefined,
  });

  // 204 No Content など Body が空のケース
  let body: unknown = null;
  if (response.status !== 204) {
    const text = await response.text();
    if (text.length > 0) {
      try {
        body = JSON.parse(text);
      } catch {
        body = text;
      }
    }
  }

  if (!response.ok) {
    const message =
      typeof body === 'object' && body !== null && 'error' in body
        ? ((body as { error?: { message?: string } }).error?.message ?? 'リクエストに失敗しました')
        : 'リクエストに失敗しました';
    throw new ApiError(response.status, body, message);
  }

  // Authorization ヘッダから JWT を抽出して保存（signup/login 時のため）
  const authHeader =
    response.headers.get('Authorization') ?? response.headers.get('authorization');
  if (authHeader) {
    const t = authHeader.replace(/^Bearer\s+/i, '');
    setToken(t);
  }

  return { data: body as T, authHeader };
}

export const apiClient = {
  get: <T>(path: string, query?: RequestOptions['query']) =>
    request<T>(path, { method: 'GET', query }).then((r) => r.data),
  post: <T>(path: string, json?: unknown) =>
    request<T>(path, { method: 'POST', json }).then((r) => r.data),
  patch: <T>(path: string, json?: unknown) =>
    request<T>(path, { method: 'PATCH', json }).then((r) => r.data),
  delete: <T = void>(path: string) =>
    request<T>(path, { method: 'DELETE' }).then((r) => r.data),
};
