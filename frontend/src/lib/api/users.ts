import { apiClient } from './client';
import type { ApiCollection, ApiResponse, PostResource, UserResource } from './types';

export async function fetchUser(handle: string): Promise<ApiResponse<UserResource>> {
  return apiClient.get<ApiResponse<UserResource>>(`users/${handle}`);
}

export async function fetchUserPosts(handle: string): Promise<ApiCollection<PostResource>> {
  return apiClient.get<ApiCollection<PostResource>>(`users/${handle}/posts`);
}

export async function followUser(handle: string): Promise<{ data: { status: string } }> {
  return apiClient.post<{ data: { status: string } }>(`users/${handle}/follow`);
}

export async function unfollowUser(handle: string): Promise<void> {
  await apiClient.delete(`users/${handle}/follow`);
}
