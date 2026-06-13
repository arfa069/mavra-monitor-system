import api from "@/shared/api/client";
import type { User } from "../types";

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}

export interface WeChatQrResponse {
  qr_url: string;
  state: string;
}

export interface WeChatBindRequest {
  temp_token: string;
  username: string;
  password: string;
}

export interface WeChatRegisterRequest {
  temp_token: string;
  username: string;
  email: string;
  password: string;
}

export const authApi = {
  login: (data: LoginRequest) => api.post<User>("/auth/login", data),

  register: (data: RegisterRequest) =>
    api.post<User>("/auth/register", data),

  getWeChatQr: (nextPath?: string) =>
    api.get<WeChatQrResponse>("/auth/wechat/qr", {
      params: nextPath ? { next: nextPath } : undefined,
    }),

  bindWeChat: (data: WeChatBindRequest) =>
    api.post<User>("/auth/wechat/bind", data),

  registerWithWeChat: (data: WeChatRegisterRequest) =>
    api.post<User>("/auth/wechat/register", data),

  logout: () => api.post("/auth/logout"),

  getMe: () => api.get<User>("/auth/me"),

  updateProfile: async (data: { username?: string; email?: string }) => {
    const response = await api.patch<User>("/auth/me", data);
    return response;
  },

  changePassword: async (data: {
    old_password: string;
    new_password: string;
  }) => {
    const response = await api.post("/auth/me/password", data);
    return response;
  },

  updateConfig: async (data: {
    feishu_webhook_url?: string;
    data_retention_days?: number;
  }) => {
    const response = await api.patch("/auth/me/config", data);
    return response;
  },
};
