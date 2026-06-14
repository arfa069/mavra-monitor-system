import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  smartHomeCallService,
  smartHomeGetConfig,
  smartHomeListEntities,
} from "@/shared/api/generated/smart-home/smart-home";
import { smartHomeApi } from "@/features/smart-home/api/smartHome";

vi.mock("@/shared/api/generated/smart-home/smart-home", () => ({
  smartHomeGetConfig: vi.fn(),
  smartHomeUpdateConfig: vi.fn(),
  smartHomeTestConfig: vi.fn(),
  smartHomeListEntities: vi.fn(),
  smartHomeGetSummary: vi.fn(),
  smartHomeCallService: vi.fn(),
}));

describe("smartHomeApi", () => {
  beforeEach(() => {
    vi.mocked(smartHomeCallService).mockReset();
    vi.mocked(smartHomeGetConfig).mockReset();
    vi.mocked(smartHomeListEntities).mockReset();
  });

  it("places slash-bearing entity IDs in the service request body", async () => {
    vi.mocked(smartHomeCallService).mockResolvedValue({
      ok: true,
      entity_id: "light.office/main",
      service: "turn_on",
      message: "Service call sent",
    });

    await smartHomeApi.callService("light.office/main", {
      service: "turn_on",
      service_data: { brightness: 50 },
    });

    expect(smartHomeCallService).toHaveBeenCalledWith({
      entity_id: "light.office/main",
      service: "turn_on",
      service_data: { brightness: 50 },
    });
  });

  it("normalizes optional generated entity fields for UI consumers", async () => {
    vi.mocked(smartHomeListEntities).mockResolvedValue({
      connected: true,
      items: [
        {
          domain: "light",
          entity_id: "light.office",
          name: "Office Light",
          state: "on",
        },
      ],
      total: 1,
    });

    await expect(smartHomeApi.listEntities()).resolves.toMatchObject({
      last_error: null,
      items: [
        {
          area: null,
          attributes: {},
          available: true,
          last_changed: null,
          last_updated: null,
        },
      ],
    });
  });

  it("normalizes optional generated config fields for UI consumers", async () => {
    vi.mocked(smartHomeGetConfig).mockResolvedValue({
      id: 1,
      base_url: "http://homeassistant.local",
      enabled: true,
      created_at: "2026-06-14T00:00:00Z",
      updated_at: "2026-06-14T00:00:00Z",
    });

    await expect(smartHomeApi.getConfig()).resolves.toMatchObject({
      last_status: null,
      last_error: null,
      token_configured: true,
    });
  });
});
