import { apiClient } from './client';
import type {
  ApiCollection,
  ApiResponse,
  LikeToggleResponse,
  PostResource,
} from './types';

export async function fetchHomeTimeline(): Promise<ApiCollection<PostResource>> {
  return apiClient.get<ApiCollection<PostResource>>('timeline/home');
}

export async function fetchExploreTimeline(): Promise<ApiCollection<PostResource>> {
  return apiClient.get<ApiCollection<PostResource>>('timeline/explore');
}

export async function fetchPost(id: string): Promise<ApiResponse<PostResource>> {
  return apiClient.get<ApiResponse<PostResource>>(`posts/${id}`);
}

export async function createPost(body: string, bookId?: string): Promise<ApiResponse<PostResource>> {
  const json = bookId ? { post: { body, book_id: bookId } } : { post: { body } };
  return apiClient.post<ApiResponse<PostResource>>('posts', json);
}

export async function deletePost(id: string): Promise<void> {
  await apiClient.delete(`posts/${id}`);
}

export async function likePost(id: string): Promise<LikeToggleResponse> {
  return apiClient.post<LikeToggleResponse>(`posts/${id}/like`);
}

export async function unlikePost(id: string): Promise<LikeToggleResponse> {
  return apiClient.delete<LikeToggleResponse>(`posts/${id}/like`);
}
