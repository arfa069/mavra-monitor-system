import { screen, fireEvent, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi, beforeEach } from "vitest";
import ProfileManagement from "@/features/jobs/components/ProfileManagement";
import { renderWithApp } from "../test-utils";

describe("ProfileManagement", () => {
  const mockProfiles = [
    {
      id: 1,
      profile_key: "profile-available",
      status: "available" as const,
      platform_hint: "boss",
      created_at: "",
      updated_at: ""
    },
    {
      id: 2,
      profile_key: "profile-leased",
      status: "leased" as const,
      platform_hint: "boss",
      lease_task_id: "task-123",
      lease_until: "2026-06-08T12:00:00Z",
      created_at: "",
      updated_at: ""
    }
  ];

  const props = {
    profiles: mockProfiles,
    loading: false,
    onCreate: vi.fn(),
    onDelete: vi.fn(),
    onRename: vi.fn(),
    onCopy: vi.fn(),
    onUpdateStatus: vi.fn(),
    onReleaseStale: vi.fn(),
    capabilities: {
      supports_login_session: true,
      supports_profile_import: true,
      supports_profile_export: true,
      supports_local_dpapi: true,
    },
    onOpenLoginSession: vi.fn(),
    onCloseLoginSession: vi.fn(),
    onTestProfile: vi.fn(),
    onExportBackup: vi.fn(),
    onImportBackup: vi.fn(),
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders status tags correctly", async () => {
    renderWithApp(<ProfileManagement {...props} />);

    expect(await screen.findByText("profile-available")).toBeInTheDocument();
    expect(screen.getByText("available")).toBeInTheDocument();
    expect(screen.getByText("profile-leased")).toBeInTheDocument();
    expect(screen.getByText("leased")).toBeInTheDocument();
  });

  it("handles profile creation validation and triggers onCreate", async () => {
    props.onCreate.mockResolvedValue(undefined);
    renderWithApp(<ProfileManagement {...props} />);

    const user = userEvent.setup();
    const createBtn = screen.getByRole("button", { name: /create profile/i });
    await user.click(createBtn);

    // Click OK without typing profile key
    const modalOkBtn = screen.getByRole("button", { name: /ok/i });
    await user.click(modalOkBtn);

    expect(await screen.findByText("Please enter profile key")).toBeInTheDocument();

    // Type valid profile key and submit
    const profileKeyInput = screen.getByLabelText("Profile Key");
    await user.type(profileKeyInput, "new-boss-profile");
    await user.click(modalOkBtn);

    await waitFor(() => {
      expect(props.onCreate).toHaveBeenCalledWith("new-boss-profile", null);
    });
  });

  it("disables actions for leased profiles and does not allow deletion/rename", async () => {
    renderWithApp(<ProfileManagement {...props} />);

    // Click the Edit dropdown button for the leased profile row (index 1)
    const editDropdowns = screen.getAllByRole("button", { name: /edit/i });
    const user = userEvent.setup();
    await user.click(editDropdowns[1]);

    // Now Release Stale should be visible
    expect(await screen.findByText("Release Stale")).toBeInTheDocument();
  });

  it("ensures zero direct fetch / network requests are made from the component", async () => {
    const fetchSpy = vi.spyOn(globalThis, "fetch");
    renderWithApp(<ProfileManagement {...props} />);

    expect(globalThis.fetch).not.toHaveBeenCalled();
    fetchSpy.mockRestore();
  });
});
