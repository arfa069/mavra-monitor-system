import api from "@/shared/api/client";

export function exportProfileBackup(profileKey: string, password: string) {
  return api.post<Blob>(
    `/crawl-profiles/${encodeURIComponent(profileKey)}/export`,
    { password },
    { responseType: "blob" },
  );
}

export function importProfileBackup(
  profileKey: string,
  file: File,
  password: string,
  force: boolean,
) {
  const form = new FormData();
  form.append("file", file);
  form.append("password", password);
  form.append("force", String(force));
  return api.post<{ profile_key: string; imported: boolean }>(
    `/crawl-profiles/${encodeURIComponent(profileKey)}/import`,
    form,
  );
}
