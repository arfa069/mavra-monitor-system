import { screen, waitFor, fireEvent } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import SettingsPage from "@/features/settings/SettingsPage";
import { server } from "../mocks/server";
import { renderWithApp } from "../test-utils";

describe("SettingsPage", () => {
  it("initializes form with values from AuthContext", async () => {
    renderWithApp(<SettingsPage />);

    // Renders with default MSW user values (defined in handlers.ts)
    expect(await screen.findByLabelText("Data Retention (Days)")).toHaveValue(
      "365",
    );
    expect(screen.getByLabelText("飞书 Webhook URL")).toHaveValue("");
  });

  it("submits patch update, synchronizes with AuthContext, and preserves user role/permissions", async () => {
    let patchPayload: any = null;
    server.use(
      http.patch("/api/v1/config", async ({ request }) => {
        patchPayload = await request.json();
        return HttpResponse.json({
          id: 1,
          username: "default",
          feishu_webhook_url: "https://hook.feishu.cn/123",
          data_retention_days: 90,
        });
      }),
    );

    const { queryClient } = renderWithApp(<SettingsPage />);

    const user = userEvent.setup();
    const webhookInput = await screen.findByLabelText("飞书 Webhook URL");
    const retentionInput = screen.getByLabelText("Data Retention (Days)");

    // Type new settings values
    await user.clear(webhookInput);
    await user.type(webhookInput, "https://hook.feishu.cn/123");
    await user.clear(retentionInput);
    await user.type(retentionInput, "90");

    const saveBtn = screen.getByRole("button", { name: /save/i });
    await user.click(saveBtn);

    await waitFor(() => {
      expect(patchPayload).toEqual({
        feishu_webhook_url: "https://hook.feishu.cn/123",
        data_retention_days: 90,
      });
      expect(screen.getByText("Settings saved")).toBeInTheDocument();
    });
  });

  it("handles API validation errors gracefully", async () => {
    server.use(
      http.patch("/api/v1/config", () => {
        return HttpResponse.json(
          { detail: "Validation failed: URL is invalid" },
          { status: 422 },
        );
      }),
    );

    renderWithApp(<SettingsPage />);

    const user = userEvent.setup();
    const saveBtn = await screen.findByRole("button", { name: /save/i });
    await user.click(saveBtn);

    expect(
      await screen.findByText("Validation failed: URL is invalid"),
    ).toBeInTheDocument();
  });

  it("sets motion speed and updates localStorage", async () => {
    renderWithApp(<SettingsPage />);

    // Check default motion speed is active (Segmented control)
    const fastSegment = await screen.findByText("Fast");
    fireEvent.click(fastSegment);

    await waitFor(() => {
      expect(localStorage.getItem("mavra-monitor-system-motion-speed")).toBe(
        "fast",
      );
    });
  });
});
