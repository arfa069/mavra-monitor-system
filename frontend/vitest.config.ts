import { mergeConfig } from "vite";
import { defineConfig } from "vitest/config";
import viteConfig from "./vite.config";

export default mergeConfig(
  viteConfig,
  defineConfig({
    test: {
      environment: "jsdom",
      setupFiles: ["./tests/unit/setup.ts"],
      clearMocks: true,
      restoreMocks: true,
      mockReset: true,
      coverage: {
        provider: "v8",
        reporter: ["text", "html", "lcov"],
        include: ["src/**/*.{ts,tsx}"],
        exclude: [
          "src/main.tsx",
          "src/**/index.ts",
          "src/**/*.d.ts",
          "src/**/types.ts",
        ],
        thresholds: {
          lines: 65,
          statements: 65,
          functions: 60,
          branches: 55
        }
      }
    }
  })
);
