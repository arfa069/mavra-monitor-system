export const adminUser = {
  id: 1,
  username: "default",
  email: "default@example.com",
  role: "super_admin",
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
    "smart_home:control",
    "smart_home:configure",
  ],
};

export const readOnlyUser = {
  id: 2,
  username: "readonly",
  email: "readonly@example.com",
  role: "user",
  permissions: [
    "user:read",
    "schedule:read",
    "product:read",
    "job:read",
    "smart_home:read",
  ],
};

export const mockProducts = [
  {
    id: 1,
    name: "Synthetic Marketplace Item A",
    title: "Synthetic Marketplace Item A",
    platform: "taobao",
    url: "https://example.invalid/product/taobao-a",
    price: 99.9,
    target_price: 90.0,
    alert_enabled: true,
    created_at: "2026-06-08T00:00:00Z",
    updated_at: "2026-06-08T01:00:00Z",
  },
  {
    id: 2,
    name: "Synthetic Marketplace Item B",
    title: "Synthetic Marketplace Item B",
    platform: "jd",
    url: "https://example.invalid/product/jd-b",
    price: 299.0,
    target_price: 300.0,
    alert_enabled: false,
    created_at: "2026-06-08T00:00:00Z",
    updated_at: "2026-06-08T01:00:00Z",
  },
];

export const mockJobConfigs = [
  {
    id: 1,
    name: "Boss Software Engineer Monitor",
    platform: "boss",
    url: "https://example.invalid/boss/job-1",
    profile_key: "boss_chrome_profile",
    is_active: true,
    cron_expr: "0 9 * * *",
    timezone: "Asia/Shanghai",
    created_at: "2026-06-08T00:00:00Z",
  },
  {
    id: 2,
    name: "Liepin Python Dev Monitor",
    platform: "liepin",
    url: "https://example.invalid/liepin/job-2",
    profile_key: "liepin_chrome_profile",
    is_active: false,
    cron_expr: null,
    timezone: "Asia/Shanghai",
    created_at: "2026-06-08T00:00:00Z",
  },
];

export const mockJobResults = [
  {
    id: 1,
    config_id: 1,
    title: "Senior Python Developer",
    company: "Synthetic Tech Corp",
    salary: "25k-35k",
    city: "Shanghai",
    url: "https://example.invalid/boss/job-1/detail",
    crawled_at: "2026-06-08T02:00:00Z",
  },
];

export const mockProfiles = [
  {
    key: "boss_chrome_profile",
    profile_key: "boss_chrome_profile",
    platform: "boss",
    platform_hint: "boss",
    status: "idle",
    is_locked: false,
    last_used_at: "2026-06-08T01:30:00Z",
  },
  {
    key: "liepin_chrome_profile",
    profile_key: "liepin_chrome_profile",
    platform: "liepin",
    platform_hint: "liepin",
    status: "leased",
    is_locked: true,
    last_used_at: "2026-06-08T01:45:00Z",
  },
];

export const mockEvents = {
  items: [
    {
      id: "evt-1",
      kind: "system",
      event_type: "crawl.completed",
      category: "crawler",
      severity: "info",
      message: "Taobao crawler scanned 2 items.",
      occurred_at: "2026-06-08T03:00:00Z",
      source: "crawler",
      status: "success",
      user_id: 1,
      entity_type: "crawler",
      entity_id: "taobao",
      trace_id: "trace-1",
      payload: null,
    },
    {
      id: "evt-2",
      kind: "platform",
      event_type: "smart_home.sync_failed",
      category: "smart_home",
      severity: "warning",
      message: "Failed to connect to Home Assistant.",
      occurred_at: "2026-06-08T02:50:00Z",
      source: "smart_home",
      status: "error",
      user_id: 1,
      entity_type: "smart_home",
      entity_id: "ha",
      trace_id: "trace-2",
      payload: null,
    },
  ],
  total: 2,
};

export const mockSmartHomeConfig = {
  url: "https://example.invalid/ha-api",
  token_configured: true,
  status: "connected",
};

export const mockSmartHomeEntities = [
  {
    entity_id: "light.living_room_light",
    name: "Living Room Light",
    state: "on",
    attributes: { brightness: 255 },
  },
  {
    entity_id: "switch.smart_plug",
    name: "Smart Plug",
    state: "off",
    attributes: {},
  },
];

export const mockAdminUsers = [
  {
    id: 1,
    username: "default",
    email: "default@example.com",
    role: "super_admin",
    is_active: true,
    permissions: adminUser.permissions,
    created_at: "2026-06-01T00:00:00Z",
  },
  {
    id: 2,
    username: "readonly",
    email: "readonly@example.com",
    role: "user",
    is_active: true,
    permissions: readOnlyUser.permissions,
    created_at: "2026-06-02T00:00:00Z",
  },
];
