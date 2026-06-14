import { beforeEach, describe, expect, it, vi } from "vitest";
import api from "@/shared/api/client";
import {
  customInstance,
  normalizeGeneratedApiUrl,
} from "@/shared/api/mutator";

vi.mock("@/shared/api/client", () => ({
  default: vi.fn(),
}));

describe("Orval Axios mutator", () => {
  beforeEach(() => {
    vi.mocked(api).mockReset();
  });

  it("removes exactly one canonical prefix", () => {
    expect(normalizeGeneratedApiUrl("/api/v1/products")).toBe("/products");
    expect(normalizeGeneratedApiUrl("/api/v1")).toBe("/");
  });

  it("preserves query strings", () => {
    expect(normalizeGeneratedApiUrl("/api/v1/products?page=2")).toBe(
      "/products?page=2",
    );
  });

  it("rejects infrastructure and double-prefixed URLs", () => {
    expect(() => normalizeGeneratedApiUrl("/health")).toThrow(
      "non-canonical URL",
    );
    expect(() =>
      normalizeGeneratedApiUrl("/api/v1/api/v1/products"),
    ).toThrow("double API prefix");
  });

  it("merges generated and caller headers before using shared Axios", async () => {
    vi.mocked(api).mockResolvedValue({ data: { id: 1 } } as never);

    await customInstance(
      {
        url: "/api/v1/products",
        method: "POST",
        headers: { "Content-Type": "application/json" },
        data: { title: "A" },
      },
      { headers: { "X-Test": "yes" } },
    );

    expect(api).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "/products",
        headers: expect.objectContaining({
          "Content-Type": "application/json",
          "X-Test": "yes",
        }),
      }),
    );
  });
});
