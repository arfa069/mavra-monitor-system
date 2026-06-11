import { describe, expect, it } from "vitest";
import robots from "./robots";

describe("robots", () => {
  it("allows the blog path and points crawlers to the sitemap", () => {
    const result = robots();

    expect(result.rules).toEqual({
      userAgent: "*",
      allow: "/blog",
    });
    expect(result.sitemap).toBe("http://localhost:3001/sitemap.xml");
  });
});
