import type { PropsWithChildren, ReactElement } from "react";
import { App, ConfigProvider } from "antd";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { render } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { AuthProvider } from "@/shared/contexts/AuthContext";
import { ThemeProvider } from "@/shared/components/ThemeProvider";

export function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: {
      queries: { retry: false, gcTime: 0 },
      mutations: { retry: false },
    },
  });
}

export function renderWithApp(
  ui: ReactElement,
  options: { route?: string; withAuth?: boolean } = {},
) {
  const queryClient = createTestQueryClient();
  const Wrapper = ({ children }: PropsWithChildren) => {
    const content =
      options.withAuth === false ? (
        children
      ) : (
        <AuthProvider>{children}</AuthProvider>
      );

    return (
      <MemoryRouter initialEntries={[options.route ?? "/"]}>
        <QueryClientProvider client={queryClient}>
          <ThemeProvider>
            <ConfigProvider>
              <App>{content}</App>
            </ConfigProvider>
          </ThemeProvider>
        </QueryClientProvider>
      </MemoryRouter>
    );
  };

  return { queryClient, ...render(ui, { wrapper: Wrapper }) };
}
