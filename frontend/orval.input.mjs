export const ORVAL_EXCLUDED_PATHS = [
  "/api/v1",
  "/api/v1/auth/wechat/callback",
  "/api/v1/crawl-profiles/{profile_key}/export",
  "/api/v1/dashboard/events",
  "/api/v1/events/stream",
  "/api/v1/smart-home/entities/stream",
  "/blog-media/{file_name}",
  "/health",
  "/health/detailed",
];

const excluded = new Set(ORVAL_EXCLUDED_PATHS);

export default function filterOrvalInput(spec) {
  return {
    ...spec,
    paths: Object.fromEntries(
      Object.entries(spec.paths ?? {}).filter(([path]) => !excluded.has(path)),
    ),
  };
}
