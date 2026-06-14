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
  UserLogin,
  UserRegister,
  WeChatBindRequest,
  WeChatRegisterRequest,
  ProfileUpdate,
  PasswordChange,
} from "@/shared/api/generated/models";

export const authApi = {
  login: (data: UserLogin) => authLogin(data),

  register: (data: UserRegister) => authRegister(data),

  getWeChatQr: (nextPath?: string) =>
    wechatGetWechatQrUrl({ next: nextPath || undefined }),

  bindWeChat: (data: WeChatBindRequest) => wechatBindWechatAccount(data),

  registerWithWeChat: (data: WeChatRegisterRequest) =>
    wechatRegisterWithWechat(data),

  logout: () => authLogout(),

  getMe: () => authGetMe(),

  updateProfile: (data: ProfileUpdate) => authUpdateMe(data),

  changePassword: (data: PasswordChange) => authChangePassword(data),
};
