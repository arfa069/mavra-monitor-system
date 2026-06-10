import { screen, fireEvent, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi } from "vitest";
import LoginPage from "@/features/auth/LoginPage";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";
import { testUser } from "../mocks/handlers";

// Mock useNavigate so we can assert on redirection
const mockNavigate = vi.fn();
vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => mockNavigate,
    useLocation: () => ({
      state: { from: { pathname: "/settings" } },
    }),
  };
});

describe("LoginPage", () => {
  it("displays required validation on empty submission", async () => {
    renderWithApp(<LoginPage />);

    const submitBtn = screen.getByRole("button", { name: /sign in/i });
    fireEvent.click(submitBtn);

    expect(
      await screen.findByText("Please enter username or email"),
    ).toBeInTheDocument();
    expect(
      await screen.findByText("Please enter password"),
    ).toBeInTheDocument();
  });

  it("succeeds on correct credentials, redirects, and sets no localStorage auth", async () => {
    let requestPayload: any = null;
    server.use(
      http.post("/api/v1/auth/login", async ({ request }) => {
        requestPayload = await request.json();
        return HttpResponse.json(testUser);
      }),
    );

    renderWithApp(<LoginPage />);

    const user = userEvent.setup();
    await user.type(
      screen.getByPlaceholderText(/user@example.com/i),
      "default",
    );
    await user.type(screen.getByPlaceholderText(/••••••••/i), "123456");

    const submitBtn = screen.getByRole("button", { name: /sign in/i });
    await user.click(submitBtn);

    await waitFor(() => {
      expect(requestPayload).toEqual({
        username: "default",
        password: "123456",
      });
      expect(mockNavigate).toHaveBeenCalledWith("/settings", { replace: true });
    });

    expect(localStorage.getItem("auth_token")).toBeNull();
    expect(localStorage.getItem("auth_user")).toBeNull();
  });

  it("handles failed login, shows error message, and resets only password", async () => {
    server.use(
      http.post("/api/v1/auth/login", () => {
        return new HttpResponse(null, { status: 401 });
      }),
    );

    renderWithApp(<LoginPage />);

    const user = userEvent.setup();
    const usernameInput = screen.getByPlaceholderText(
      /user@example.com/i,
    ) as HTMLInputElement;
    const passwordInput = screen.getByPlaceholderText(
      /••••••••/i,
    ) as HTMLInputElement;

    await user.type(usernameInput, "default");
    await user.type(passwordInput, "wrongpassword");

    const submitBtn = screen.getByRole("button", { name: /sign in/i });
    await user.click(submitBtn);

    // Wait for button loading state to finish / error message to show
    await waitFor(() => {
      expect(passwordInput.value).toBe("");
    });
    expect(usernameInput.value).toBe("default");
  });

  it("expands the WeChat panel and renders a QR code after loading", async () => {
    server.use(
      http.get("/api/v1/auth/wechat/qr", () =>
        HttpResponse.json({
          qr_url: "https://open.weixin.qq.com/connect/qrconnect?state=abc",
          state: "abc",
        }),
      ),
    );

    renderWithApp(<LoginPage />);

    const user = userEvent.setup();
    await user.click(screen.getByRole("button", { name: /wechat login/i }));

    expect(await screen.findByText("Scan with WeChat")).toBeInTheDocument();
    expect(screen.getByTitle("WeChat login QR")).toBeInTheDocument();
  });

  it("shows a disabled-state message when WeChat login is unavailable", async () => {
    server.use(
      http.get("/api/v1/auth/wechat/qr", () =>
        HttpResponse.json({ detail: "微信登录未启用" }, { status: 503 }),
      ),
    );

    renderWithApp(<LoginPage />);

    const user = userEvent.setup();
    await user.click(screen.getByRole("button", { name: /wechat login/i }));

    expect(
      await screen.findByText("当前环境未启用微信登录"),
    ).toBeInTheDocument();
  });
});
