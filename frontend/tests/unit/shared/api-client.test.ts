import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import api, { formatApiError } from "@/shared/api/client";
import { server } from "../mocks/server";

describe("shared API client", () => {
  it("formats string and validation-list errors", () => {
    expect(
      formatApiError({ response: { data: { detail: "denied" } } } as any, "fallback")
    ).toBe("denied");
    expect(
      formatApiError(
        { response: { data: { detail: [{ msg: "first" }, "second"] } } } as any,
        "fallback"
      )
    ).toBe("first; second");
  });

  it("adds the CSRF cookie to unsafe requests", async () => {
    document.cookie = "pm_csrf_token=csrf-test; Path=/";
    server.use(
      http.patch("/api/v1/config", async ({ request }) => {
        expect(request.headers.get("X-CSRF-Token")).toBe("csrf-test");
        return HttpResponse.json({ ok: true });
      })
    );

    await api.patch("/v1/config", { data_retention_days: 30 });
  });

  it("queues concurrent 401 requests and calls refresh only once", async () => {
    let refreshCalls = 0;
    let p1Calls = 0;
    let p2Calls = 0;

    server.use(
      http.post("/api/v1/auth/refresh", () => {
        refreshCalls++;
        return HttpResponse.json({ ok: true });
      }),
      http.get("/api/v1/protected-1", () => {
        p1Calls++;
        if (p1Calls === 1) {
          return new HttpResponse(null, { status: 401 });
        }
        return HttpResponse.json({ data: "p1-success" });
      }),
      http.get("/api/v1/protected-2", () => {
        p2Calls++;
        if (p2Calls === 1) {
          return new HttpResponse(null, { status: 401 });
        }
        return HttpResponse.json({ data: "p2-success" });
      })
    );

    const [res1, res2] = await Promise.all([
      api.get("/v1/protected-1"),
      api.get("/v1/protected-2")
    ]);

    expect(res1.data).toEqual({ data: "p1-success" });
    expect(res2.data).toEqual({ data: "p2-success" });
    expect(refreshCalls).toBe(1);
    expect(p1Calls).toBe(2);
    expect(p2Calls).toBe(2);
  });
});
