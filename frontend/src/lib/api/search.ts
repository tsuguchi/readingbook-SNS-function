import { apiClient } from './client';
import type { BookResource, PostResource, UserResource } from './types';

export type HashtagResource = {
  id: string;
  type: 'hashtag';
  attributes: { name: string; counts: { posts: number } };
};

export type SearchAllResponse = {
  data: {
    users?: UserResource[];
    books?: BookResource[];
    posts?: PostResource[];
    tags?: HashtagResource[];
  };
};

export async function searchAll(q: string): Promise<SearchAllResponse> {
  return apiClient.get<SearchAllResponse>('search', { q });
}

export async function search(q: string, type: 'users' | 'books' | 'posts' | 'tags'): Promise<SearchAllResponse> {
  return apiClient.get<SearchAllResponse>('search', { q, type });
}
