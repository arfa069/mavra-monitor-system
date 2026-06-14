import { describe, expect, it } from "vitest";
import { encodePathSegment } from "@/shared/api/path";

describe("encodePathSegment", () => {
  it("encodes URL-reserved characters once", () => {
    expect(encodePathSegment("profile name#1")).toBe("profile%20name%231");
  });
});
