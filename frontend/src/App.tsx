import { type ReactNode, useMemo } from "react";
import React from "react";
import {
  BrowserRouter,
  Routes,
  Route,
  Navigate,
  Outlet,
  useLocation,
} from "react-router-dom";
import { App as AntdApp, ConfigProvider, Spin, theme } from "antd";
import { AuthProvider, useAuth } from "@/shared/contexts/AuthContext";
import type { Permission } from "@/shared/types";
import AppLayout from "@/shared/components/AppLayout";
import {
  ThemeProvider,
  useThemeContext,
} from "@/shared/components/ThemeProvider";
const JobsPage = React.lazy(() => import("@/features/jobs"));
const ProductsPage = React.lazy(() => import("@/features/products"));
const AdminUsersPage = React.lazy(() =>
  import("@/features/admin").then((m) => ({ default: m.AdminUsersPage })),
);
const AdminAuditLogsPage = React.lazy(() =>
  import("@/features/admin").then((m) => ({ default: m.AdminAuditLogsPage })),
);
const LoginPage = React.lazy(() =>
  import("@/features/auth").then((m) => ({ default: m.LoginPage })),
);
const RegisterPage = React.lazy(() =>
  import("@/features/auth").then((m) => ({ default: m.RegisterPage })),
);
const ProfilePage = React.lazy(() =>
  import("@/features/auth").then((m) => ({ default: m.ProfilePage })),
);
const EventCenterPage = React.lazy(() =>
  import("@/features/events").then((m) => ({ default: m.EventCenterPage })),
);
const DashboardPage = React.lazy(() =>
  import("@/features/dashboard").then((m) => ({ default: m.DashboardPage })),
);
const SettingsPage = React.lazy(() =>
  import("@/features/settings").then((m) => ({ default: m.SettingsPage })),
);
const ScheduleConfigPage = React.lazy(() =>
  import("@/features/schedule").then((m) => ({
    default: m.ScheduleConfigPage,
  })),
);
const SmartHomePage = React.lazy(() => import("@/features/smart-home"));

function PageLoader({ fullScreen }: { fullScreen?: boolean }) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        minHeight: fullScreen ? "100vh" : "400px",
        height: "100%",
        width: "100%",
        background: "var(--color-canvas)",
      }}
    >
      <Spin size="large" />
    </div>
  );
}

// Error Fallback component (does not use router hooks so it can render outside Router)
function ErrorFallback() {
  return (
    <div
      style={{
        height: "100vh",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        background: "var(--color-canvas)",
        fontFamily: "var(--font-body)",
      }}
    >
      <div style={{ fontSize: 48, marginBottom: 16 }}>⚠️</div>
      <div
        style={{
          fontSize: 18,
          fontWeight: 600,
          color: "var(--color-ink)",
          marginBottom: 8,
        }}
      >
        Page load failed
      </div>
      <div
        style={{ fontSize: 14, color: "var(--color-muted)", marginBottom: 24 }}
      >
        Please refresh the page or contact an administrator
      </div>
      <button
        onClick={() => { window.location.href = "/login"; }}
        style={{
          padding: "8px 16px",
          background: "var(--color-primary)",
          color: "var(--color-on-primary)",
          border: "none",
          borderRadius: 6,
          cursor: "pointer",
          fontSize: 14,
        }}
      >
        Back to Login
      </button>
    </div>
  );
}

// Error Boundary component
class ErrorBoundary extends React.Component<
  { children: ReactNode; fallback?: ReactNode },
  { hasError: boolean; error?: Error }
> {
  constructor(props: { children: ReactNode; fallback?: ReactNode }) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error) {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.warn("ErrorBoundary caught:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      if (this.props.fallback) return this.props.fallback;
      return <ErrorFallback />;
    }
    return this.props.children;
  }
}

// Protected route component - requires login
function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  const location = useLocation();

  if (isLoading) {
    return <PageLoader fullScreen />;
  }

  if (!isAuthenticated) {
    // Redirect to login page, save current location to return after login
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return children;
}

// Permission route - requires specific permission
function PermissionRoute({
  permission,
  children,
}: {
  permission: Permission;
  children: ReactNode;
}) {
  const { user, isLoading, hasPermission } = useAuth();

  if (isLoading) {
    return <PageLoader fullScreen />;
  }

  if (!user || !hasPermission(permission)) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}

// Public route - redirects authenticated users to home
function PublicRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();

  if (isLoading) {
    return <PageLoader fullScreen />;
  }

  if (isAuthenticated) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
}

function ProtectedLayoutRoute() {
  return (
    <ProtectedRoute>
      <AppLayout>
        <React.Suspense fallback={<PageLoader />}>
          <Outlet />
        </React.Suspense>
      </AppLayout>
    </ProtectedRoute>
  );
}

function AppRoutes() {
  const { theme: currentTheme } = useThemeContext();

  const antdTheme = useMemo(
    () => ({
      algorithm:
        currentTheme === "dark" ? theme.darkAlgorithm : theme.defaultAlgorithm,
      token: {
        colorPrimary: currentTheme === "dark" ? "#ffffff" : "#000000",
        colorBgLayout: currentTheme === "dark" ? "#0e0e11" : "#f8f6f0",
        colorBgContainer: currentTheme === "dark" ? "#1b1b24" : "#fbf6e3",
        colorText: currentTheme === "dark" ? "#ffffff" : "#000000",
        colorTextSecondary: currentTheme === "dark" ? "#888888" : "#666666",
        colorBorder: currentTheme === "dark" ? "#ffffff" : "#000000",
        colorBorderSecondary: currentTheme === "dark" ? "#ffffff" : "#000000",
        colorSuccess: currentTheme === "dark" ? "#00ff66" : "#b8f2a1",
        colorWarning: currentTheme === "dark" ? "#ff7f00" : "#ffb88c",
        colorError: currentTheme === "dark" ? "#ff007f" : "#ffb3d9",
        colorInfo: currentTheme === "dark" ? "#00f0ff" : "#99f0f9",
        borderRadius: 8,
        fontSize: 14,
        fontFamily: "'Outfit', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif",
        fontFamilyCode: "'JetBrains Mono', monospace",
      },
      components: {
        Button: {
          borderRadius: 9999,
          paddingInline: 20,
          controlHeight: 40,
        },
        Input: {
          borderRadius: 8,
          paddingInline: 14,
          controlHeight: 40,
        },
        Select: {
          borderRadius: 8,
          controlHeight: 40,
        },
        Table: {
          borderRadius: 8,
          headerBg: currentTheme === "dark" ? "#8b3dff" : "#fbee6b",
        },
        Card: {
          borderRadius: 16,
        },
        Tag: {
          borderRadius: 9999,
        },
        Menu: {
          itemSelectedBg: currentTheme === "dark" ? "#00ff66" : "#b8f2a1",
          itemSelectedColor: "#000000",
        },
      },
    }),
    [currentTheme],
  );

  return (
    <ConfigProvider theme={antdTheme}>
      <AntdApp>
        <BrowserRouter>
          <React.Suspense fallback={<PageLoader fullScreen />}>
            <Routes>
              {/* Public routes */}
              <Route
                path="/login"
                element={
                  <PublicRoute>
                    <LoginPage />
                  </PublicRoute>
                }
              />
              <Route
                path="/register"
                element={
                  <PublicRoute>
                    <RegisterPage />
                  </PublicRoute>
                }
              />

              {/* Protected routes */}
              <Route element={<ProtectedLayoutRoute />}>
                <Route path="/dashboard" element={<DashboardPage />} />
                <Route path="/events" element={<EventCenterPage />} />
                <Route path="/jobs" element={<JobsPage />} />
                <Route path="/products" element={<ProductsPage />} />
                <Route path="/schedule" element={<ScheduleConfigPage />} />
                <Route path="/smart-home" element={<SmartHomePage />} />
                <Route path="/profile" element={<ProfilePage />} />
                <Route path="/settings" element={<SettingsPage />} />
                <Route
                  path="/admin/users"
                  element={
                    <PermissionRoute permission="user:read">
                      <AdminUsersPage />
                    </PermissionRoute>
                  }
                />
                <Route
                  path="/admin/audit-logs"
                  element={
                    <PermissionRoute permission="user:read">
                      <AdminAuditLogsPage />
                    </PermissionRoute>
                  }
                />
              </Route>

              {/* Default routes */}
              <Route path="/" element={<Navigate to="/dashboard" replace />} />
              <Route path="*" element={<Navigate to="/dashboard" replace />} />
            </Routes>
          </React.Suspense>
        </BrowserRouter>
      </AntdApp>
    </ConfigProvider>
  );
}

export default function App() {
  return (
    <ErrorBoundary>
      <ThemeProvider>
        <AuthProvider>
          <AppRoutes />
        </AuthProvider>
      </ThemeProvider>
    </ErrorBoundary>
  );
}
