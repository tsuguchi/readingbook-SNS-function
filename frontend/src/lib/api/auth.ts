import { apiClient, setToken } from './client';
import type { LoginResponse } from './types';

export async function signup(input: {
  email: string;
  password: string;
  handle: string;
  display_name: string;
}): Promise<LoginResponse> {
  const body = await apiClient.post<LoginResponse>('auth/signup', { auth: input });
  if (body.meta?.token) setToken(body.meta.token);
  return body;
}

export async function login(input: { email: string; password: string }): Promise<LoginResponse> {
  const body = await apiClient.post<LoginResponse>('auth/login', { auth: input });
  if (body.meta?.token) setToken(body.meta.token);
  return body;
}

export async function logout(): Promise<void> {
  try {
    await apiClient.delete('auth/logout');
  } finally {
    setToken(null);
  }
}

export async function fetchMe(): Promise<LoginResponse> {
  return apiClient.get<LoginResponse>('me');
}
