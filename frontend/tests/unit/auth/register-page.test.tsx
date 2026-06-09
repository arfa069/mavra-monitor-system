import { screen, fireEvent, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi } from "vitest";
import RegisterPage from "@/features/auth/RegisterPage";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";
import { authApi } from "@/features/auth/api/auth";

// Mock useNavigate so we can assert on redirection
const mockNavigate = vi.fn();
vi.mock("react-router-dom", async () => {
  const actual = await vi.importActual("react-router-dom");
  return {
    ...actual,
    useNavigate: () => mockNavigate,
    Link: ({ children, to }: any) => <a href={to}>{children}</a>,
  };
});

describe("RegisterPage", () => {
  it("displays required validations on empty submit", async () => {
    renderWithApp(<RegisterPage />);

    const submitBtn = screen.getByRole("button", { name: /sign up/i });
    fireEvent.click(submitBtn);

    expect(
      await screen.findByText("Please enter username"),
    ).toBeInTheDocument();
    expect(await screen.findByText("Please enter email")).toBeInTheDocument();
    expect(
      await screen.findByText("Please enter password"),
    ).toBeInTheDocument();

    // Custom validator and required validator might both trigger, causing duplicates
    await waitFor(async () => {
      const confirmErrors = await screen.findAllByText(
        "Please confirm password",
      );
      expect(confirmErrors.length).toBeGreaterThan(0);
    });
  });

  it("validates password mismatch", async () => {
    renderWithApp(<RegisterPage />);

    const user = userEvent.setup();
    await user.type(screen.getByPlaceholderText("Username"), "newuser");
    await user.type(screen.getByPlaceholderText("Email"), "new@example.com");
    await user.type(screen.getByPlaceholderText("Password"), "123456");
    await user.type(screen.getByPlaceholderText("Confirm Password"), "123457");

    const submitBtn = screen.getByRole("button", { name: /sign up/i });
    await user.click(submitBtn);

    expect(
      await screen.findByText("Passwords do not match"),
    ).toBeInTheDocument();
  });

  it("registers successfully and navigates to login page", async () => {
    let requestPayload: any = null;
    server.use(
      http.post("/api/v1/auth/register", async ({ request }) => {
        requestPayload = await request.json();
        return HttpResponse.json({
          id: 2,
          username: "newuser",
          email: "new@example.com",
          role: "user",
          permissions: [],
        });
      }),
    );

    renderWithApp(<RegisterPage />);

    const user = userEvent.setup();
    await user.type(screen.getByPlaceholderText("Username"), "newuser");
    await user.type(screen.getByPlaceholderText("Email"), "new@example.com");
    await user.type(screen.getByPlaceholderText("Password"), "123456");
    await user.type(screen.getByPlaceholderText("Confirm Password"), "123456");

    const submitBtn = screen.getByRole("button", { name: /sign up/i });
    await user.click(submitBtn);

    await waitFor(() => {
      expect(requestPayload).toEqual({
        username: "newuser",
        email: "new@example.com",
        password: "123456",
        password_confirm: "123456",
      });
      expect(mockNavigate).toHaveBeenCalledWith("/login", { replace: true });
    });
  });

  it("handles registration API errors and resets password inputs", async () => {
    const registerSpy = vi.spyOn(authApi, "register");
    server.use(
      http.post("/api/v1/auth/register", () => {
        return new HttpResponse(null, { status: 400 });
      }),
    );

    renderWithApp(<RegisterPage />);

    const user = userEvent.setup();
    const usernameInput = screen.getByPlaceholderText(
      "Username",
    ) as HTMLInputElement;
    const emailInput = screen.getByPlaceholderText("Email") as HTMLInputElement;
    const passwordInput = screen.getByPlaceholderText(
      "Password",
    ) as HTMLInputElement;
    const confirmInput = screen.getByPlaceholderText(
      "Confirm Password",
    ) as HTMLInputElement;

    await user.type(usernameInput, "newuser");
    await user.type(emailInput, "new@example.com");
    await user.type(passwordInput, "123456");
    await user.type(confirmInput, "123456");

    const submitBtn = screen.getByRole("button", { name: /sign up/i });
    await user.click(submitBtn);

    await waitFor(() => {
      expect(registerSpy).toHaveBeenCalled();
    });

    await waitFor(() => {
      expect(passwordInput.value).toBe("");
      expect(confirmInput.value).toBe("");
    });
    expect(usernameInput.value).toBe("newuser");
    expect(emailInput.value).toBe("new@example.com");

    registerSpy.mockRestore();
  });
});
