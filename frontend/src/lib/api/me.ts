import { apiClient } from './client';
import type { ApiResponse, UserResource } from './types';

export type ProfileUpdate = {
  display_name?: string;
  bio?: string;
  is_private?: boolean;
  reading_goal?: number | null;
};

export async function updateProfile(input: ProfileUpdate): Promise<ApiResponse<UserResource>> {
  return apiClient.patch<ApiResponse<UserResource>>('me', { me: input });
}
