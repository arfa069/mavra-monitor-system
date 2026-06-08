import { describe, expect, it } from "vitest";
import { mergeRealtimeEvent } from "../../src/features/events/realtimeState";
import { isValidCronExpression } from "../../src/features/schedule/utils/cron";
import { applyUserConfig } from "../../src/features/settings/userConfigState";

describe("review regressions", () => {
  it("increments total only for a new realtime event", () => {
    const first = { id: "first", kind: "system" } as never;
    const next = { id: "next", kind: "system" } as never;
    const added = mergeRealtimeEvent({ items: [first], total: 1 }, next, 20);

    expect(added.items).toEqual([next, first]);
    expect(added.total).toBe(2);
    expect(mergeRealtimeEvent(added, next, 20)).toBe(added);
  });

  it("preserves auth fields while applying saved settings", () => {
    const user = {
      id: 7,
      username: "default",
      email: "default@example.com",
      role: "admin" as const,
      permissions: ["config:read" as const],
      feishu_webhook_url: "old",
      data_retention_days: 365
    };

    expect(
      applyUserConfig(user, {
        id: 7,
        username: "default",
        feishu_webhook_url: "new",
        data_retention_days: 180,
        created_at: null,
        updated_at: null
      })
    ).toEqual({
      ...user,
      feishu_webhook_url: "new",
      data_retention_days: 180
    });
  });

  it("rejects malformed cron expressions", () => {
    expect(isValidCronExpression("0 9 * * *")).toBe(true);
    expect(isValidCronExpression("bad_cron")).toBe(false);
  });
});
