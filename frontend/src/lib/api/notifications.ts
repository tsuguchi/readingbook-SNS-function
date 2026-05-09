import { apiClient } from './client';
import type { ApiCollection, ApiResponse, UserResource, PostResource, CommentResource } from './types';

export type NotificationType =
  | 'like_post'
  | 'like_comment'
  | 'follow'
  | 'follow_request'
  | 'follow_accepted'
  | 'repost'
  | 'quote_repost'
  | 'comment';

export type NotificationResource = {
  id: string;
  type: 'notification';
  attributes: {
    notification_type: NotificationType;
    read_at: string | null;
    created_at: string;
    actor: UserResource;
    target: PostResource | CommentResource | null;
  };
};

export async function fetchNotifications(unreadOnly = false): Promise<ApiCollection<NotificationResource>> {
  return apiClient.get<ApiCollection<NotificationResource>>('notifications', {
    unread_only: unreadOnly ? 'true' : undefined,
  });
}

export async function markNotificationRead(id: string): Promise<void> {
  await apiClient.post(`notifications/${id}/read`);
}

export async function markAllNotificationsRead(): Promise<void> {
  await apiClient.post('notifications/read_all');
}

export async function fetchUnreadCount(): Promise<ApiResponse<{ unread_count: number }>> {
  return apiClient.get<ApiResponse<{ unread_count: number }>>('notifications/unread_count');
}
