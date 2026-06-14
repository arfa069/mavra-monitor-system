import {
  authLogin,
  authRegister,
  authLogout,
  authGetMe,
  authUpdateMe,
  authChangePassword,
} from "@/shared/api/generated/auth/auth";
import {
  wechatGetWechatQrUrl,
  wechatBindWechatAccount,
  wechatRegisterWithWechat,
} from "@/shared/api/generated/wechat/wechat";
import type {
  UserResponse,
  UserLogin,
  UserRegister,
  WeChatBindRequest,
  WeChatRegisterRequest,
  ProfileUpdate,
  PasswordChange,
} from "@/shared/api/generated/models";
import type { Permission, User } from "@/shared/types";

const KNOWN_PERMISSIONS: ReadonlySet<string> = new Set([
  "user:read",
  "user:manage",
  "user:delete",
  "crawl:execute",
  "crawl:read_logs",
  "schedule:read",
  "schedule:configure",
  "config:read",
  "config:write",
  "product:read",
  "product:write",
  "product:delete",
  "job:read",
  "job:write",
  "job:delete",
  "rbac:read",
  "rbac:manage",
  "smart_home:read",
  "smart_home:control",
  "smart_home:configure",
  "blog:read_admin",
  "blog:write",
  "blog:publish",
]);

function isPermission(value: string): value is Permission {
  return KNOWN_PERMISSIONS.has(value);
}

export function normalizeUserResponse(response: UserResponse): User {
  const role =
    response.role === "admin" || response.role === "super_admin"
      ? response.role
      : "user";

  return {
    ...response,
    role,
    permissions: (response.permissions ?? []).filter(isPermission),
  };
}

export const authApi = {
  login: async (data: UserLogin) => normalizeUserResponse(await authLogin(data)),

  register: async (data: UserRegister) =>
    normalizeUserResponse(await authRegister(data)),

  getWeChatQr: (nextPath?: string) =>
    wechatGetWechatQrUrl({ next: nextPath || undefined }),

  bindWeChat: async (data: WeChatBindRequest) =>
    normalizeUserResponse(await wechatBindWechatAccount(data)),

  registerWithWeChat: async (data: WeChatRegisterRequest) =>
    normalizeUserResponse(await wechatRegisterWithWechat(data)),

  logout: () => authLogout(),

  getMe: async () => normalizeUserResponse(await authGetMe()),

  updateProfile: async (data: ProfileUpdate) =>
    normalizeUserResponse(await authUpdateMe(data)),

  changePassword: (data: PasswordChange) => authChangePassword(data),
};
