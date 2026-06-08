import { renderHook, act, waitFor } from "@testing-library/react";
import { describe, expect, it, vi, beforeEach } from "vitest";
import { useJobConfigSchedule } from "@/features/schedule/hooks/useJobConfigSchedule";
import { jobsApi } from "@/features/jobs";

vi.mock("@/features/jobs", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/features/jobs")>();
  return {
    ...actual,
    jobsApi: {
      getConfigs: vi.fn(),
      getJobConfigSchedules: vi.fn(),
      updateConfigCron: vi.fn()
    }
  };
});

describe("useJobConfigSchedule Hook", () => {
  const mockMessage = {
    error: vi.fn(),
    success: vi.fn()
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("load() merges config rows and scheduler status by config_id", async () => {
    const mockConfigs = [
      { id: 1, name: "JD Config", platform: "jd", cron_expression: "0 9 * * *" },
      { id: 2, name: "Taobao Config", platform: "taobao", cron_expression: "" }
    ];
    const mockSchedules = {
      configs: [
        { config_id: 1, active: true, next_run: "2026-06-08T09:00:00Z" }
      ]
    };

    vi.mocked(jobsApi.getConfigs).mockResolvedValue({ data: mockConfigs } as any);
    vi.mocked(jobsApi.getJobConfigSchedules).mockResolvedValue({ data: mockSchedules } as any);

    const { result } = renderHook(() => useJobConfigSchedule(mockMessage));

    await act(async () => {
      await result.current.load();
    });

    expect(result.current.list).toEqual(mockConfigs);
    expect(result.current.schedules).toEqual({
      1: { config_id: 1, active: true, next_run: "2026-06-08T09:00:00Z" }
    });
    expect(result.current.cronInputs).toEqual({
      1: "0 9 * * *",
      2: ""
    });
  });

  it("save rejects invalid cron expression and does not call API", async () => {
    const { result } = renderHook(() => useJobConfigSchedule(mockMessage));

    await act(async () => {
      await result.current.save(1, "bad_cron");
    });

    expect(jobsApi.updateConfigCron).not.toHaveBeenCalled();
    expect(mockMessage.error).toHaveBeenCalledWith("Invalid cron expression");
  });

  it("save sends timezone Asia/Shanghai and reloads on success", async () => {
    const mockConfigs = [
      { id: 1, name: "JD Config", platform: "jd", cron_expression: "0 9 * * *" }
    ];
    const mockSchedules = { configs: [] };

    vi.mocked(jobsApi.getConfigs).mockResolvedValue({ data: mockConfigs } as any);
    vi.mocked(jobsApi.getJobConfigSchedules).mockResolvedValue({ data: mockSchedules } as any);
    vi.mocked(jobsApi.updateConfigCron).mockResolvedValue({} as any);

    const { result } = renderHook(() => useJobConfigSchedule(mockMessage));

    await act(async () => {
      await result.current.save(1, "0 9 * * *");
    });

    expect(jobsApi.updateConfigCron).toHaveBeenCalledWith(1, {
      cron_expression: "0 9 * * *",
      cron_timezone: "Asia/Shanghai"
    });
    expect(mockMessage.success).toHaveBeenCalledWith("Saved");
    expect(jobsApi.getConfigs).toHaveBeenCalled(); // verified reload
  });

  it("save displays Save failed and clears per-row saving flag on error", async () => {
    let rejectCron: (reason: any) => void = () => {};
    const cronPromise = new Promise((_, reject) => {
      rejectCron = reject;
    });
    vi.mocked(jobsApi.updateConfigCron).mockReturnValue(cronPromise as any);

    const { result } = renderHook(() => useJobConfigSchedule(mockMessage));

    act(() => {
      void result.current.save(1, "0 9 * * *");
    });

    // Verify saving is true while promise is pending
    await waitFor(() => {
      expect(result.current.saving[1]).toBe(true);
    });

    await act(async () => {
      rejectCron(new Error("API Error"));
      try {
        await cronPromise;
      } catch {
        // ignore expected rejection
      }
    });

    // Verify saving is false after promise completes
    await waitFor(() => {
      expect(result.current.saving[1]).toBe(false);
    });
    expect(mockMessage.error).toHaveBeenCalledWith("Save failed");
  });

  it("accepts null/blank cron expression to disable the schedule", async () => {
    vi.mocked(jobsApi.updateConfigCron).mockResolvedValue({} as any);
    vi.mocked(jobsApi.getConfigs).mockResolvedValue({ data: [] } as any);
    vi.mocked(jobsApi.getJobConfigSchedules).mockResolvedValue({ data: { configs: [] } } as any);

    const { result } = renderHook(() => useJobConfigSchedule(mockMessage));

    await act(async () => {
      await result.current.save(1, null);
    });

    expect(jobsApi.updateConfigCron).toHaveBeenCalledWith(1, {
      cron_expression: null,
      cron_timezone: "Asia/Shanghai"
    });
    expect(mockMessage.success).toHaveBeenCalledWith("Saved");
  });
});
