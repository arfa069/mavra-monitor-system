/**
 * Formats a date value to a human-readable string.
 * Defaults to "en-US" with medium date style and short time style.
 */
export function formatDateTime(
  value: string | Date | number | null | undefined,
): string {
  if (!value) return "-";
  const date = typeof value === "object" ? value : new Date(value);
  return new Intl.DateTimeFormat("en-US", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}
