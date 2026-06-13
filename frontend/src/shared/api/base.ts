const DEFAULT_API_BASE_URL = "/api/v1";

export const API_BASE_URL = (
  import.meta.env.VITE_API_URL?.trim() || DEFAULT_API_BASE_URL
).replace(/\/+$/, "");

export function apiUrl(path: `/${string}`): string {
  return `${API_BASE_URL}${path}`;
}
