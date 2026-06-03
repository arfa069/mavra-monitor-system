import { notification } from "antd";
import axios, { AxiosError } from "axios";
import type { InternalAxiosRequestConfig } from "axios";

type ErrorDetailItem = { msg?: string } | string;
type ErrorResponse = { detail?: ErrorDetailItem[] | string };

function getCookie(name: string): string | null {
  const match = document.cookie.match(new RegExp(`(^| )${name}=([^;]+)`));
  return match ? decodeURIComponent(match[2]) : null;
}

const api = axios.create({
  baseURL: "/api",
  timeout: 300000,
  withCredentials: true,
});

// Request interceptor: add CSRF header for unsafe methods
api.interceptors.request.use(
  (config) => {
    if (
      config.method &&
      ["post", "patch", "put", "delete"].includes(config.method)
    ) {
      const csrfToken = getCookie("pm_csrf_token");
      if (csrfToken && config.headers) {
        config.headers["X-CSRF-Token"] = csrfToken;
      }
    }
    return config;
  },
  (error) => Promise.reject(error),
);

const handleServerError = (status: number, msg: string) => {
  notification.error({
    message: `Server Error (${status})`,
    description: msg,
    duration: 6,
    placement: "topRight",
  });
};

const handleTimeout = () => {
  notification.warning({
    message: "Request Timeout",
    description: "Server is responding slowly, please try again later",
    duration: 6,
    placement: "topRight",
  });
};

const formatDetail = (detail: ErrorResponse["detail"], fallback: string) => {
  if (Array.isArray(detail)) {
    return detail
      .map((item) => (typeof item === "string" ? item : item.msg || fallback))
      .join("; ");
  }
  return detail || fallback;
};

// Track retries to avoid infinite loops
let isRefreshing = false;

interface FailedRequest {
  resolve: (value: unknown) => void;
  reject: (reason: unknown) => void;
  config: InternalAxiosRequestConfig & { _retry?: boolean };
}

let failedQueue: FailedRequest[] = [];

api.interceptors.response.use(
  (res) => res,
  async (err: AxiosError<ErrorResponse>) => {
    if (!err.config) {
      return Promise.reject(err);
    }

    const originalRequest = err.config as InternalAxiosRequestConfig & {
      _retry?: boolean;
    };

    if (
      err.response?.status === 401 &&
      !originalRequest._retry &&
      originalRequest.url !== "/v1/auth/login" &&
      originalRequest.url !== "/v1/auth/me"
    ) {
      if (isRefreshing) {
        // Queue request until refresh completes
        originalRequest._retry = true;
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject, config: originalRequest });
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      try {
        await axios.post("/api/v1/auth/refresh", {}, { withCredentials: true });
        // Retry all queued original requests
        failedQueue.forEach(({ resolve, reject, config }) => {
          api(config).then(resolve).catch(reject);
        });
        failedQueue = [];
        return api(originalRequest);
      } catch {
        failedQueue.forEach(({ reject }) => reject(err));
        failedQueue = [];
        window.location.href = "/login";
        return Promise.reject(err);
      } finally {
        isRefreshing = false;
      }
    }

    if (err.response?.status && err.response.status >= 500) {
      handleServerError(err.response.status, err.message);
    } else if (err.response?.status && err.response.status >= 400) {
      err.message = formatDetail(
        err.response.data?.detail,
        `Request failed (${err.response.status})`,
      );
    } else if (err.code === "ECONNABORTED" || !err.response) {
      handleTimeout();
    }
    return Promise.reject(err);
  },
);

export default api;
