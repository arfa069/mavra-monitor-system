import { screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it, vi } from "vitest";

import ProfilePage from "@/features/auth/ProfilePage";
import { authApi } from "@/features/auth/api/auth";
import { renderWithApp } from "../test-utils";
import { server } from "../mocks/server";


describe("ProfilePage password policy", () => {
  it("blocks weak new passwords before submit", async () => {
    const changePasswordSpy = vi.spyOn(authApi, "changePassword");

    renderWithApp(<ProfilePage />);

    const user = userEvent.setup();
    await user.type(
      await screen.findByLabelText("Current Password"),
      "CurrentPass1!",
    );
    await user.type(screen.getByLabelText("New Password"), "alllowercase1!");
    await user.click(screen.getByRole("button", { name: "Change Password" }));

    const messages = await screen.findAllByText(
      "Password must be at least 10 characters and include uppercase, lowercase, number, and special character",
    );
    expect(messages.length).toBeGreaterThan(0);
    expect(changePasswordSpy).not.toHaveBeenCalled();

    changePasswordSpy.mockRestore();
  });

  it("shows backend strong-password error message", async () => {
    server.use(
      http.post("/api/v1/auth/me/password", () =>
        HttpResponse.json(
          {
            detail:
              "密码必须至少 10 位，并同时包含大写字母、小写字母、数字和特殊字符",
          },
          { status: 422 },
        ),
      ),
    );

    renderWithApp(<ProfilePage />);

    const user = userEvent.setup();
    await user.type(
      await screen.findByLabelText("Current Password"),
      "CurrentPass1!",
    );
    await user.type(screen.getByLabelText("New Password"), "ValidPass1!");
    await user.click(screen.getByRole("button", { name: "Change Password" }));

    await waitFor(() => {
      expect(
        screen.getByText(
          "密码必须至少 10 位，并同时包含大写字母、小写字母、数字和特殊字符",
        ),
      ).toBeInTheDocument();
    });
  });
});
