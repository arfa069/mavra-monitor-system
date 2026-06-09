import { screen, fireEvent, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import AdminUsersPage from "@/features/admin/AdminUsersPage";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";

describe("AdminUsersPage", { timeout: 30000 }, () => {
  const mockUsersList = {
    items: [
      {
        id: 1,
        username: "super-admin-user",
        email: "admin@example.com",
        role: "super_admin",
        is_active: true,
        permissions: ["user:read", "user:manage"],
        created_at: "2026-06-08T00:00:00Z",
        updated_at: "2026-06-08T00:00:00Z",
      },
      {
        id: 2,
        username: "normal-user",
        email: "user@example.com",
        role: "user",
        is_active: true,
        permissions: ["user:read"],
        created_at: "2026-06-08T00:00:00Z",
        updated_at: "2026-06-08T00:00:00Z",
      },
    ],
    total: 2,
  };

  it("renders user table but hides action controls for read-only user", async () => {
    // Mock user without user:manage or user:delete
    const readOnlyUser = {
      id: 10,
      username: "read-only-guy",
      email: "readonly@example.com",
      role: "user",
      permissions: ["user:read"], // Only user:read
    };

    server.use(
      http.get("/api/v1/auth/me", () => HttpResponse.json(readOnlyUser)),
      http.get("/api/v1/admin/users", () => HttpResponse.json(mockUsersList)),
    );

    renderWithApp(<AdminUsersPage />);

    // Table should render the users
    expect(await screen.findByText("super-admin-user")).toBeInTheDocument();
    expect(screen.getByText("normal-user")).toBeInTheDocument();

    // New User button should not be present
    expect(
      screen.queryByRole("button", { name: /new user/i }),
    ).not.toBeInTheDocument();

    // Edit and Delete actions in the table should be disabled
    const editButtons = screen.getAllByRole("button", { name: /edit/i });
    const deleteButtons = screen.getAllByRole("button", { name: /delete/i });
    editButtons.forEach((btn) => expect(btn).toBeDisabled());
    deleteButtons.forEach((btn) => expect(btn).toBeDisabled());
  });

  it("shows management controls for users with user:manage and user:delete permissions", async () => {
    // Mock user with manage and delete permissions
    const managerUser = {
      id: 11,
      username: "manager-guy",
      email: "manager@example.com",
      role: "admin",
      permissions: ["user:read", "user:manage", "user:delete"],
    };

    server.use(
      http.get("/api/v1/auth/me", () => HttpResponse.json(managerUser)),
      http.get("/api/v1/admin/users", () => HttpResponse.json(mockUsersList)),
    );

    renderWithApp(<AdminUsersPage />);

    // New User button should be present
    expect(
      await screen.findByRole("button", { name: /new user/i }),
    ).toBeInTheDocument();

    // Actions column with Edit / Delete should be enabled
    const editButtons = screen.getAllByRole("button", { name: /edit/i });
    const deleteButtons = screen.getAllByRole("button", { name: /delete/i });
    expect(editButtons[1]).not.toBeDisabled();
    expect(deleteButtons[1]).not.toBeDisabled();
  });
});
