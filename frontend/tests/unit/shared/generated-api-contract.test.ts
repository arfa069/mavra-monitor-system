import { readFileSync, readdirSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

const generatedRoot = join(
  process.cwd(),
  "src",
  "shared",
  "api",
  "generated",
);

function generatedFiles(directory: string): string[] {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    return entry.isDirectory() ? generatedFiles(path) : [path];
  });
}

describe("generated API tree", () => {
  it("contains Axios output without stale path-family artifacts", () => {
    const files = generatedFiles(generatedRoot);
    const source = files
      .filter((file) => file.endsWith(".ts"))
      .map((file) => readFileSync(file, "utf8"))
      .join("\n");
    const names = files.map((file) => file.split(/[\\/]/).at(-1) ?? "");

    expect(source).not.toContain("RequestInit");
    expect(source).not.toMatch(/(?:return `|["'])\/v1\//);
    expect(source).not.toContain('return `/health');
    expect(names.some((name) => name.includes("ApiV1"))).toBe(false);
    expect(names.some((name) => /^.*V1.*Params\.ts$/.test(name))).toBe(false);
  });
});
