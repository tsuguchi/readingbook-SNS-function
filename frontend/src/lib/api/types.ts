// バックエンド API のレスポンス型定義（jsonapi-serializer 形式 + 独自）
//
// 取り回しやすさ重視で、最低限の構造だけ定義する。
// 厳密な型は次フェーズで openapi-typescript により自動生成へ移行予定。

export type UserAttributes = {
  handle: string;
  display_name: string;
  avatar_url: string | null;
  bio: string | null;
  is_private: boolean;
  reading_goal: number | null;
  created_at: string;
  counts: { posts: number; followers: number; following: number };
};

export type UserResource = {
  id: string;
  type: 'user';
  attributes: UserAttributes;
};

export type BookAttributes = {
  title: string;
  author: string | null;
  isbn: string | null;
  cover_url: string | null;
  published_on: string | null;
  counts?: { likes: number; posts: number };
  is_liked?: boolean;
};

export type BookResource = {
  id: string;
  type: 'book';
  attributes: BookAttributes;
};

export type PostAttributes = {
  body: string;
  created_at: string;
  updated_at: string;
  user: UserResource;
  book: BookResource | null;
  hashtags: string[];
  counts: { likes: number; comments: number; reposts: number };
  is_liked: boolean;
  is_reposted: boolean;
};

export type PostResource = {
  id: string;
  type: 'post';
  attributes: PostAttributes;
};

export type CommentResource = {
  id: string;
  type: 'comment';
  attributes: {
    body: string;
    created_at: string;
    post_id: string;
    user: UserResource;
    counts: { likes: number };
    is_liked: boolean;
  };
};

export type ApiResponse<T> = { data: T };
export type ApiCollection<T> = { data: T[] };
export type ApiError = { error: { code: string; message: string; details?: { field: string; message: string }[] } };

export type LoginResponse = ApiResponse<UserResource> & { meta: { token: string } };
export type LikeToggleResponse = ApiResponse<{ is_liked: boolean; likes_count: number }>;
