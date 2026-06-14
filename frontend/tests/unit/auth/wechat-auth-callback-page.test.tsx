import { screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";

import WeChatAuthCallbackPage from "@/features/auth/WeChatAuthCallbackPage";
import { renderWithApp } from "../test-utils";
import { testUser } from "../mocks/handlers";

const mockNavigate = vi.fn();
const mockLogin = vi.fn();
const mockGetMe = vi.fn();
const mockLocation = {
  pathname: "/auth/wechat/callback",
  search: "",
  hash: "",
};

vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => mockNavigate,
    useLocation: () => mockLocation,
  };
});

vi.mock("@/shared/contexts/AuthContext", () => ({
  useAuth: () => ({
    login: mockLogin,
  }),
}));

vi.mock("@/features/auth/api/auth", () => ({
  authApi: {
    getMe: (...args: unknown[]) => mockGetMe(...args),
  },
}));

vi.mock("@/features/auth/components/WeChatAccountLinkPanel", () => ({
  default: ({
    nextPath,
    tempToken,
  }: {
    nextPath: string;
    tempToken: string;
  }) => (
    <div data-testid="wechat-account-link-panel">
      {nextPath}:{tempToken}
    </div>
  ),
}));

describe("WeChatAuthCallbackPage", () => {
  beforeEach(() => {
    mockNavigate.mockReset();
    mockLogin.mockReset();
    mockGetMe.mockReset();
    mockLocation.pathname = "/auth/wechat/callback";
    mockLocation.search = "";
    mockLocation.hash = "";
  });

  it("restores auth and navigates to the next path on success", async () => {
    mockLocation.search = "?status=success&next=%2Fjobs";
    mockGetMe.mockResolvedValue(testUser);

    renderWithApp(<WeChatAuthCallbackPage />, { withAuth: false });

    await waitFor(() => {
      expect(mockGetMe).toHaveBeenCalledTimes(1);
      expect(mockLogin).toHaveBeenCalledWith(testUser);
      expect(mockNavigate).toHaveBeenCalledWith("/jobs", { replace: true });
    });
  });

  it("renders the account-link panel for unbound callbacks", async () => {
    mockLocation.search = "?status=unbound&next=%2Ftoday";
    mockLocation.hash = "#temp_token=temp-1";

    renderWithApp(<WeChatAuthCallbackPage />, { withAuth: false });

    expect(
      await screen.findByTestId("wechat-account-link-panel"),
    ).toHaveTextContent("/today:temp-1");
  });

  it("removes temp_token from the browser hash after parsing", async () => {
    mockLocation.search = "?status=unbound&next=%2Ftoday";
    mockLocation.hash = "#temp_token=temp-1";
    const replaceStateSpy = vi.spyOn(window.history, "replaceState");

    renderWithApp(<WeChatAuthCallbackPage />, { withAuth: false });

    await waitFor(() => {
      expect(replaceStateSpy).toHaveBeenCalledWith(
        {},
        document.title,
        "/auth/wechat/callback?status=unbound&next=%2Ftoday",
      );
    });
  });

  it("shows an error message for callback failures", async () => {
    mockLocation.search = "?status=error&reason=state_expired";

    renderWithApp(<WeChatAuthCallbackPage />, { withAuth: false });

    expect(
      await screen.findByText("微信登录失败，请重新扫码"),
    ).toBeInTheDocument();
  });
});
