import { beforeEach, describe, expect, it, vi } from "vitest";
import { authLogin } from "@/shared/api/generated/auth/auth";
import { authApi } from "@/features/auth/api/auth";

vi.mock("@/shared/api/generated/auth/auth", () => ({
  authLogin: vi.fn(),
  authRegister: vi.fn(),
  authLogout: vi.fn(),
  authGetMe: vi.fn(),
  authUpdateMe: vi.fn(),
  authChangePassword: vi.fn(),
}));

vi.mock("@/shared/api/generated/wechat/wechat", () => ({
  wechatGetWechatQrUrl: vi.fn(),
  wechatBindWechatAccount: vi.fn(),
  wechatRegisterWithWechat: vi.fn(),
}));

describe("authApi", () => {
  beforeEach(() => {
    vi.mocked(authLogin).mockReset();
  });

  it("normalizes generated users before exposing application state", async () => {
    vi.mocked(authLogin).mockResolvedValue({
      id: 7,
      username: "operator",
      email: "operator@example.com",
      role: "unexpected-role",
      permissions: ["user:read", "not-a-real-permission"],
      created_at: "2026-06-14T00:00:00Z",
    });

    await expect(
      authApi.login({ username: "operator", password: "secret" }),
    ).resolves.toEqual({
      id: 7,
      username: "operator",
      email: "operator@example.com",
      role: "user",
      permissions: ["user:read"],
      created_at: "2026-06-14T00:00:00Z",
    });
  });
});
