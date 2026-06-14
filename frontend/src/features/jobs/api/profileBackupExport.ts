import api from "@/shared/api/client";
import { encodePathSegment } from "@/shared/api/path";

export function exportProfileBackup(profileKey: string, password: string) {
  return api.post<Blob>(
    `/crawl-profiles/${encodePathSegment(profileKey)}/export`,
    { password },
    { responseType: "blob" },
  );
}
