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
    "smart_home:read"
  ]
};

export const handlers = [
  http.get("/api/v1/auth/me", () => HttpResponse.json(testUser)),
  http.post("/api/v1/auth/logout", () =>
    HttpResponse.json({ message: "logged out" })
  )
];
