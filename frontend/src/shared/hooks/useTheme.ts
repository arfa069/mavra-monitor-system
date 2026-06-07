import { useState, useEffect, useCallback } from "react";

export type Theme = "light" | "dark";

const STORAGE_KEY = "mavra-monitor-system-theme";
const THEME_COLOR_DARK = "#0a0a0a";
const THEME_COLOR_LIGHT = "#ffffff";

function getInitialTheme(): Theme {
  try {
    const stored = localStorage.getItem(STORAGE_KEY);
    if (stored === "light" || stored === "dark") {
      return stored;
    }
  } catch {
    // localStorage unavailable (private mode, quota full, etc.), silently fall back
  }
  if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
    return "dark";
  }
  return "light";
}

function applyThemeToDOM(next: Theme) {
  document.documentElement.setAttribute("data-theme", next);
  document.documentElement.style.colorScheme = next;
  document
    .querySelector('meta[name="theme-color"]')
    ?.setAttribute(
      "content",
      next === "dark" ? THEME_COLOR_DARK : THEME_COLOR_LIGHT,
    );
}

export function useTheme() {
  const [theme, setThemeState] = useState<Theme>(getInitialTheme);

  // Sync DOM whenever theme state changes (mount + updates)
  useEffect(() => {
    applyThemeToDOM(theme);
  }, [theme]);

  const setTheme = useCallback((newTheme: Theme) => {
    setThemeState(newTheme);
    try {
      localStorage.setItem(STORAGE_KEY, newTheme);
    } catch {
      // localStorage unavailable, silently fall back
    }
  }, []);

  const toggleTheme = useCallback(() => {
    setTheme(theme === "light" ? "dark" : "light");
  }, [theme, setTheme]);

  // Listen for system preference changes
  useEffect(() => {
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");
    const handleChange = (e: MediaQueryListEvent) => {
      try {
        const stored = localStorage.getItem(STORAGE_KEY);
        if (!stored) {
          setThemeState(e.matches ? "dark" : "light");
        }
      } catch {
        // localStorage unavailable, follow system preference directly
        setThemeState(e.matches ? "dark" : "light");
      }
    };
    mediaQuery.addEventListener("change", handleChange);
    return () => mediaQuery.removeEventListener("change", handleChange);
  }, []);

  return { theme, setTheme, toggleTheme };
}
