import { http, HttpResponse } from "msw";

export const testUser = {
  id: 1,
  username: "default",
  email: "default@example.com",
  role: "super_admin" as const,
  permissions: [
    "user:read",
    "user:manage",
    "crawl:execute",
    "schedule:read",
    "schedule:configure",
    "config:read",
    "config:write",
    "product:read",
    "product:write",
    "job:read",
    "job:write",
    "smart_home:read",
  ],
};

export const handlers = [
  http.get("/api/v1/auth/me", () => HttpResponse.json(testUser)),
  http.post("/api/v1/auth/logout", () =>
    HttpResponse.json({ message: "logged out" }),
  ),
  http.get("/api/v1/dashboard/kpi", () =>
    HttpResponse.json({
      user: {
        total_products: 3,
        price_drops_today: 1,
        new_jobs_today: 2,
        match_count: 1,
        crawl_count_today: 4,
      },
      system: null,
    }),
  ),
  http.get("/api/v1/products", () =>
    HttpResponse.json({
      items: [
        {
          id: 12,
          user_id: 1,
          platform: "jd",
          url: "https://item.jd.com/12.html",
          platform_product_id: "12",
          title: "Dell 显示器",
          active: true,
          created_at: "2026-06-10T00:00:00Z",
          updated_at: "2026-06-10T00:00:00Z",
        },
      ],
      total: 1,
      page: 1,
      page_size: 5,
    }),
  ),
  http.get("/api/v1/jobs/match-results", () =>
    HttpResponse.json({
      items: [
        {
          id: 9,
          user_id: 1,
          resume_id: 1,
          job_id: 88,
          match_score: 92,
          match_reason: "Strong frontend match",
          apply_recommendation: "recommended",
          llm_model_used: "test",
          created_at: "2026-06-10T00:00:00Z",
          updated_at: "2026-06-10T00:00:00Z",
          job_title: "Frontend Engineer",
          job_company: "Example Co",
          job_salary: "30-45K",
          job_location: "Shanghai",
          job_url: "https://example.test/job",
          job_description: "Build UI",
        },
      ],
      total: 1,
      page: 1,
      page_size: 5,
    }),
  ),
  http.get("/api/v1/smart-home/config", () =>
    HttpResponse.json({
      id: 1,
      base_url: "http://homeassistant.local:8123",
      enabled: true,
      last_status: "connected",
      last_error: null,
      token_configured: true,
      created_at: "2026-06-10T00:00:00Z",
      updated_at: "2026-06-10T00:00:00Z",
    }),
  ),
  http.get("/api/v1/smart-home/summary", () =>
    HttpResponse.json({
      configured: true,
      connected: true,
      active_count: 1,
      unavailable_count: 0,
    }),
  ),
  http.get("/api/v1/smart-home/entities", () =>
    HttpResponse.json({
      items: [
        {
          entity_id: "light.living_room",
          domain: "light",
          name: "Living Room",
          state: "on",
          area: "客厅",
          attributes: {},
          last_changed: "2026-06-10T00:00:00Z",
          last_updated: "2026-06-10T00:00:00Z",
          available: true,
        },
      ],
      total: 1,
      connected: true,
      last_error: null,
    }),
  ),
];
