export type WeChatCallbackStatus = "success" | "unbound" | "error";

export interface WeChatCallbackState {
  status: WeChatCallbackStatus | null;
  next: string;
  reason: string | null;
  tempToken: string | null;
}

export function parseWeChatCallback(
  search: string,
  hash: string,
): WeChatCallbackState {
  const query = new URLSearchParams(search);
  const fragment = new URLSearchParams(hash.replace(/^#/, ""));

  return {
    status: (query.get("status") as WeChatCallbackStatus | null) ?? null,
    next: query.get("next") || "/today",
    reason: query.get("reason"),
    tempToken: fragment.get("temp_token"),
  };
}

export function clearWeChatCallbackHash(
  pathname: string,
  search: string,
): void {
  window.history.replaceState({}, document.title, `${pathname}${search}`);
}
