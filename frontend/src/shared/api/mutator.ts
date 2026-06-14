import type { AxiosError, AxiosRequestConfig } from "axios";
import api from "./client";

const CANONICAL_API_PREFIX = "/api/v1";

export function normalizeGeneratedApiUrl(url: string | undefined): string {
  if (!url) {
    throw new Error("Orval generated a request without a URL");
  }
  if (url.includes(`${CANONICAL_API_PREFIX}${CANONICAL_API_PREFIX}`)) {
    throw new Error(`Orval generated a double API prefix: ${url}`);
  }
  if (url === CANONICAL_API_PREFIX) {
    return "/";
  }
  if (!url.startsWith(`${CANONICAL_API_PREFIX}/`)) {
    throw new Error(`Orval generated a non-canonical URL: ${url}`);
  }
  return url.slice(CANONICAL_API_PREFIX.length);
}

export const customInstance = <T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig,
): Promise<T> => {
  const mergedConfig: AxiosRequestConfig = {
    ...config,
    ...options,
    headers: {
      ...config.headers,
      ...options?.headers,
    },
    url: normalizeGeneratedApiUrl(options?.url ?? config.url),
  };

  return api(mergedConfig).then(({ data }) => data);
};

export type ErrorType<Error> = AxiosError<Error>;
export type BodyType<BodyData> = BodyData;
