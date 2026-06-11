import { screen } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import AppLayout from "@/shared/components/AppLayout";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";

describe("Blog navigation permissions", () => {
  it("shows the Blog nav item when the user has blog admin access", async () => {
    renderWithApp(
      <AppLayout>
        <div>content</div>
      </AppLayout>,
      { route: "/today" },
    );

    expect(await screen.findByText("Blog")).toBeInTheDocument();
  });

  it("hides the Blog nav item when the user lacks blog admin access", async () => {
    server.use(
      http.get("/api/v1/auth/me", () =>
        HttpResponse.json({
          id: 1,
          username: "default",
          email: "default@example.com",
          role: "super_admin",
          permissions: ["user:read"],
        }),
      ),
    );

    renderWithApp(
      <AppLayout>
        <div>content</div>
      </AppLayout>,
      { route: "/today" },
    );

    expect(await screen.findByText("Users")).toBeInTheDocument();
    expect(screen.queryByText("Blog")).not.toBeInTheDocument();
  });
});
