import { describe, expect, it } from "vitest";
import filterOrvalInput, {
  ORVAL_EXCLUDED_PATHS,
} from "../../../orval.input.mjs";

describe("Orval input filter", () => {
  it("keeps canonical JSON APIs and removes special transports", () => {
    const spec = {
      paths: {
        "/api/v1/products": { get: {} },
        "/api/v1/events/stream": { get: {} },
        "/health": { get: {} },
      },
      components: { schemas: { ProductResponse: { type: "object" } } },
    };

    const filtered = filterOrvalInput(spec);

    expect(filtered.paths).toEqual({
      "/api/v1/products": { get: {} },
    });
    expect(filtered.components).toBe(spec.components);
    expect(ORVAL_EXCLUDED_PATHS).toContain("/health");
  });
});
