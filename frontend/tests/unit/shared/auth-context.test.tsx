import { StrictMode } from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi } from "vitest";
import { AuthProvider } from "@/shared/contexts/AuthContext";
import { authApi } from "@/features/auth/api/auth";
import { useAuth } from "@/shared/contexts/AuthContext";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";
import { testUser } from "../mocks/handlers";

const ProbeComponent = () => {
  const {
    user,
    isAuthenticated,
    isAdmin,
    hasPermission,
    hasAnyPermission,
    hasAllPermissions,
    login,
    logout,
  } = useAuth();
  return (
    <div>
      <span data-testid="user-info">
        {user
          ? `${user.username}:${isAuthenticated}:${isAdmin}`
          : "null:false:false"}
      </span>
      <span data-testid="permission-check">{`schedule:${hasPermission("schedule:read")}`}</span>
      <span data-testid="any-permission-check">{`any:${hasAnyPermission(["user:manage", "non-existent"])}`}</span>
      <span data-testid="all-permissions-check">{`all:${hasAllPermissions(["user:read", "user:manage"])}`}</span>
      <button
        data-testid="login-btn"
        onClick={() =>
          login({
            id: 2,
            username: "newuser",
            role: "admin",
            permissions: ["user:read"],
          } as any)
        }
      >
        Login
      </button>
      <button data-testid="logout-btn" onClick={logout}>
        Logout
      </button>
    </div>
  );
};

describe("AuthContext", () => {
  it("restores the user on successful /auth/me fetch", async () => {
    renderWithApp(<ProbeComponent />);

    expect(await screen.findByText("default:true:true")).toBeInTheDocument();
    expect(screen.getByText("schedule:true")).toBeInTheDocument();
    expect(screen.getByText("any:true")).toBeInTheDocument();
    expect(screen.getByText("all:true")).toBeInTheDocument();
  });

  it("produces unauthenticated state on /auth/me 401 response", async () => {
    server.use(
      http.get(
        "/api/v1/auth/me",
        () => new HttpResponse(null, { status: 401 }),
      ),
    );

    renderWithApp(<ProbeComponent />);

    await waitFor(() => {
      expect(screen.getByTestId("user-info")).toHaveTextContent(
        "null:false:false",
      );
    });
    expect(screen.getByText("schedule:false")).toBeInTheDocument();
  });

  it("login(user) replaces the in-memory user", async () => {
    renderWithApp(<ProbeComponent />);
    expect(await screen.findByText("default:true:true")).toBeInTheDocument();

    fireEvent.click(screen.getByTestId("login-btn"));

    await waitFor(() => {
      expect(screen.getByTestId("user-info")).toHaveTextContent(
        "newuser:true:true",
      );
    });
    expect(screen.getByText("schedule:false")).toBeInTheDocument();
  });

  it("logout() calls the API and clears the user even when the logout request fails", async () => {
    server.use(
      http.post(
        "/api/v1/auth/logout",
        () => new HttpResponse(null, { status: 500 }),
      ),
    );

    renderWithApp(<ProbeComponent />);
    expect(await screen.findByText("default:true:true")).toBeInTheDocument();

    fireEvent.click(screen.getByTestId("logout-btn"));

    await waitFor(() => {
      expect(screen.getByTestId("user-info")).toHaveTextContent(
        "null:false:false",
      );
    });
  });

  it("deduplicates auth restore during StrictMode remounts", async () => {
    const getMeSpy = vi
      .spyOn(authApi, "getMe")
      .mockResolvedValue(testUser as never);

    render(
      <StrictMode>
        <AuthProvider>
          <ProbeComponent />
        </AuthProvider>
      </StrictMode>,
    );

    expect(await screen.findByText("default:true:true")).toBeInTheDocument();
    expect(getMeSpy).toHaveBeenCalledTimes(1);
  });
});
