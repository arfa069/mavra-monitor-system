import { renderHook, act } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { ThemeProvider, useThemeContext } from "@/shared/components/ThemeProvider";
import type { ReactNode } from "react";

const wrapper = ({ children }: { children: ReactNode }) => (
  <ThemeProvider>{children}</ThemeProvider>
);

describe("ThemeProvider and useTheme", () => {
  it("initializes with default values if localStorage is empty", () => {
    const { result } = renderHook(() => useThemeContext(), { wrapper });

    expect(result.current.theme).toBe("light");
    expect(result.current.motionSpeed).toBe("normal");
  });

  it("loads stored theme and motion speed from localStorage", () => {
    localStorage.setItem("mavra-monitor-system-theme", "dark");
    localStorage.setItem("mavra-monitor-system-motion-speed", "slow");

    const { result } = renderHook(() => useThemeContext(), { wrapper });

    expect(result.current.theme).toBe("dark");
    expect(result.current.motionSpeed).toBe("slow");
    expect(localStorage.getItem("mavra-monitor-system-motion-speed")).toBe("slow");
  });

  it("falls back to normal motion speed if stored speed is invalid", () => {
    localStorage.setItem("mavra-monitor-system-motion-speed", "invalid-speed");

    const { result } = renderHook(() => useThemeContext(), { wrapper });

    expect(result.current.motionSpeed).toBe("normal");
  });

  it("falls back to system prefers-color-scheme when no theme is stored", () => {
    const originalMatchMedia = window.matchMedia;
    window.matchMedia = (query: string) => ({
      matches: query.includes("dark"),
      media: query,
      onchange: null,
      addListener: () => {},
      removeListener: () => {},
      addEventListener: () => {},
      removeEventListener: () => {},
      dispatchEvent: () => false
    } as any);

    const { result } = renderHook(() => useThemeContext(), { wrapper });

    expect(result.current.theme).toBe("dark");

    window.matchMedia = originalMatchMedia;
  });

  it("updates theme and motion speed and saves to localStorage", () => {
    const { result } = renderHook(() => useThemeContext(), { wrapper });

    act(() => {
      result.current.setTheme("dark");
    });
    expect(result.current.theme).toBe("dark");
    expect(localStorage.getItem("mavra-monitor-system-theme")).toBe("dark");

    act(() => {
      result.current.toggleTheme();
    });
    expect(result.current.theme).toBe("light");
    expect(localStorage.getItem("mavra-monitor-system-theme")).toBe("light");

    act(() => {
      result.current.setMotionSpeed("fast");
    });
    expect(result.current.motionSpeed).toBe("fast");
    expect(localStorage.getItem("mavra-monitor-system-motion-speed")).toBe("fast");
  });
});
