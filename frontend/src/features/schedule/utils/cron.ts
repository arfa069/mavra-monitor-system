import { isValidCron } from "cron-validator";

export function isValidCronExpression(value: string | null): boolean {
  if (value === null || value.trim() === "") {
    return true;
  }

  return isValidCron(value.trim(), {
    alias: true,
    allowSevenAsSunday: true,
  });
}
