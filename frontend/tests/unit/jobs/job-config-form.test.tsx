import { screen, fireEvent, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi, beforeEach } from "vitest";
import JobConfigForm from "@/features/jobs/components/JobConfigForm";
import { renderWithApp } from "../test-utils";

describe("JobConfigForm", () => {
  const onSubmit = vi.fn();
  const onCancel = vi.fn();
  const onCreateProfile = vi.fn();

  const mockProfiles = [
    { id: 1, profile_key: "default", status: "ready", platform: "boss", created_at: "", updated_at: "" },
    { id: 2, profile_key: "test-profile", status: "disabled", platform: "boss", created_at: "", updated_at: "" }
  ];

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("requires config name, URL, profile, and validates URL", async () => {
    renderWithApp(
      <JobConfigForm
        open
        profiles={mockProfiles}
        onCancel={onCancel}
        onSubmit={onSubmit}
        onCreateProfile={onCreateProfile}
      />
    );

    const okBtn = screen.getByRole("button", { name: /ok/i });
    fireEvent.click(okBtn);

    expect(await screen.findByText("Please enter config name")).toBeInTheDocument();
    expect(screen.getByText("Please enter URL")).toBeInTheDocument();

    const user = userEvent.setup();
    const urlInput = screen.getByLabelText("Boss Search URL");
    await user.type(urlInput, "not-a-url");

    expect(await screen.findByText("Invalid URL format")).toBeInTheDocument();
  });

  it("extracts keyword dynamically from search URL query parameter", async () => {
    renderWithApp(
      <JobConfigForm
        open
        profiles={mockProfiles}
        onCancel={onCancel}
        onSubmit={onSubmit}
        onCreateProfile={onCreateProfile}
      />
    );

    const user = userEvent.setup();
    const urlInput = screen.getByLabelText("Boss Search URL");
    await user.type(urlInput, "https://www.zhipin.com/web/geek/job?query=golang");

    await waitFor(() => {
      expect(screen.getByLabelText("Keyword")).toHaveValue("golang");
    });
  });

  it("populates existing configurations in edit mode", async () => {
    const mockRecord = {
      id: 10,
      name: "Existing Search",
      platform: "boss",
      profile_key: "default",
      url: "https://www.zhipin.com/web/geek/job?query=react",
      keyword: "react",
      active: true,
      notify_on_new: false,
      enable_match_analysis: true,
      deactivation_threshold: 5,
      cron_expression: "0 12 * * *",
      cron_timezone: "Asia/Shanghai",
      created_at: "",
      updated_at: ""
    };

    renderWithApp(
      <JobConfigForm
        open
        record={mockRecord}
        profiles={mockProfiles}
        onCancel={onCancel}
        onSubmit={onSubmit}
        onCreateProfile={onCreateProfile}
      />
    );

    expect(await screen.findByLabelText("Config Name")).toHaveValue("Existing Search");
    expect(screen.getByLabelText("Boss Search URL")).toHaveValue("https://www.zhipin.com/web/geek/job?query=react");
    expect(screen.getByLabelText("Keyword")).toHaveValue("react");
    expect(screen.getByLabelText("Enable Config")).toBeChecked();
    expect(screen.getByLabelText("New Job Notification")).not.toBeChecked();
    expect(screen.getByLabelText("Auto Match After Crawl")).toBeChecked();
  });

  it("submits the form successfully with all values", async () => {
    renderWithApp(
      <JobConfigForm
        open
        profiles={mockProfiles}
        onCancel={onCancel}
        onSubmit={onSubmit}
        onCreateProfile={onCreateProfile}
      />
    );

    const user = userEvent.setup();

    await user.type(screen.getByLabelText("Config Name"), "New Search");
    await user.type(screen.getByLabelText("Boss Search URL"), "https://www.zhipin.com/web/geek/job?query=rust");
    
    // Choose profile (already defaults to 'default')
    const okBtn = screen.getByRole("button", { name: /ok/i });
    await user.click(okBtn);

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          name: "New Search",
          platform: "boss",
          profile_key: "default",
          url: "https://www.zhipin.com/web/geek/job?query=rust",
          keyword: "rust"
        })
      );
    });
  });

  it("triggers onCreateProfile when creating a new profile", async () => {
    onCreateProfile.mockResolvedValue(undefined);
    renderWithApp(
      <JobConfigForm
        open
        profiles={mockProfiles}
        onCancel={onCancel}
        onSubmit={onSubmit}
        onCreateProfile={onCreateProfile}
      />
    );

    const user = userEvent.setup();
    const newProfileBtn = screen.getByRole("button", { name: "New" });
    await user.click(newProfileBtn);

    // Enter profile key in new profile modal
    const profileKeyInput = await screen.findByLabelText("Profile Key");
    await user.type(profileKeyInput, "boss-custom");

    const modalTitle = screen.getByText("New Profile");
    const newProfileModal = modalTitle.closest("[role='dialog']")!;
    const modalOkBtn = within(newProfileModal as HTMLElement).getByRole("button", { name: /ok/i });
    await user.click(modalOkBtn);

    await waitFor(() => {
      expect(onCreateProfile).toHaveBeenCalledWith("boss-custom", "boss");
    });
  });
});
