import { useState, useEffect, useMemo, useCallback } from "react";
import { m } from "framer-motion";
import {
  App,
  Layout,
  Menu,
  Button,
  Drawer,
  Avatar,
  Space,
  Dropdown,
} from "antd";
import type { MenuProps } from "antd";
import { useNavigate, useLocation } from "react-router-dom";
import {
  TeamOutlined,
  ShoppingCartOutlined,
  ScheduleOutlined,
  BarsOutlined,
  NotificationOutlined,
  UserOutlined,
  LogoutOutlined,
  SettingOutlined,
  DashboardOutlined,
  HomeOutlined,
} from "@ant-design/icons";
import { useAuth } from "@/shared/contexts/AuthContext";
import { useThemeContext } from "@/shared/components/ThemeProvider";
import PageTransition from "@/shared/components/PageTransition";

const MOBILE_BREAKPOINT = 768;

export default function AppLayout({ children }: { children: React.ReactNode }) {
  const appMessage = App.useApp().message;
  const [collapsed, setCollapsed] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  const { user, logout, hasPermission } = useAuth();
  const { theme, toggleTheme, motionSpeed } = useThemeContext();

  const handleLogout = useCallback(() => {
    logout();
    appMessage.success("Logged out");
    navigate("/login", { replace: true });
  }, [logout, appMessage, navigate]);

  const userMenuItems: MenuProps["items"] = useMemo(
    () => [
      {
        key: "profile",
        icon: <UserOutlined style={{ fontSize: 14 }} />,
        label: "Profile",
        onClick: () => navigate("/profile"),
      },
      {
        key: "settings",
        icon: <SettingOutlined style={{ fontSize: 14 }} />,
        label: "Account Settings",
        onClick: () => navigate("/settings"),
      },
      ...(hasPermission("user:read")
        ? [
            {
              key: "admin/users",
              icon: <TeamOutlined style={{ fontSize: 14 }} />,
              label: "User Management",
              onClick: () => navigate("/admin/users"),
            },
            {
              key: "admin/audit-logs",
              icon: <ScheduleOutlined style={{ fontSize: 14 }} />,
              label: "Audit Logs",
              onClick: () => navigate("/admin/audit-logs"),
            },
          ]
        : []),
      { type: "divider" as const },
      {
        key: "logout",
        icon: <LogoutOutlined style={{ fontSize: 14 }} />,
        label: "Log Out",
        danger: true,
        onClick: handleLogout,
      },
    ],
    [hasPermission, navigate, handleLogout],
  );

  useEffect(() => {
    const checkMobile = () =>
      setIsMobile(window.innerWidth < MOBILE_BREAKPOINT);
    checkMobile();
    window.addEventListener("resize", checkMobile);
    return () => window.removeEventListener("resize", checkMobile);
  }, []);

  const selectedKey = useMemo(() => {
    const path = location.pathname;
    const prefix = [
      "/today",
      "/schedule",
      "/events",
      "/jobs",
      "/products",
      "/dashboard",
      "/smart-home",
    ].find((p) => path.startsWith(p));
    if (prefix) return prefix;
    if (path.startsWith("/admin")) return path;
    return "/today";
  }, [location.pathname]);

  const handleMenuClick = ({ key }: { key: string }) => {
    navigate(key);
    if (isMobile) setDrawerOpen(false);
  };

  const menuItems = useMemo(
    () => [
      {
        key: "/today",
        icon: <HomeOutlined style={{ fontSize: 14 }} />,
        label: "Today",
      },
      {
        key: "/dashboard",
        icon: <DashboardOutlined style={{ fontSize: 14 }} />,
        label: "Analytics",
      },
      {
        key: "/events",
        icon: <NotificationOutlined style={{ fontSize: 14 }} />,
        label: "Activity",
      },
      {
        key: "/jobs",
        icon: <TeamOutlined style={{ fontSize: 14 }} />,
        label: "Jobs",
      },
      {
        key: "/products",
        icon: <ShoppingCartOutlined style={{ fontSize: 14 }} />,
        label: "Prices",
      },
      {
        key: "/schedule",
        icon: <ScheduleOutlined style={{ fontSize: 14 }} />,
        label: "Rules",
      },
      {
        key: "/smart-home",
        icon: <HomeOutlined style={{ fontSize: 14 }} />,
        label: "Home",
      },
      ...(hasPermission("user:read")
        ? [
            {
              key: "/admin/users",
              icon: <TeamOutlined style={{ fontSize: 14 }} />,
              label: "Users",
            },
            {
              key: "/admin/audit-logs",
              icon: <ScheduleOutlined style={{ fontSize: 14 }} />,
              label: "Audit Logs",
            },
          ]
        : []),
    ],
    [hasPermission],
  );

  return (
    <Layout style={{ minHeight: "100vh", background: "var(--color-canvas)" }}>
      {/* Top Nav */}
      <Layout.Header
        style={{
          position: "fixed",
          top: 0,
          left: 0,
          right: 0,
          zIndex: 300,
          display: "flex",
          alignItems: "center",
          padding: "0 24px",
          height: 56,
          background: "var(--color-canvas)",
          borderBottom: "var(--border-width) solid var(--color-border)",
          boxShadow: "none",
        }}
      >
        {/* Logo */}
        <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: "var(--radius-pill)",
              border: "1px solid var(--color-border)",
              background: "var(--color-butter)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "var(--color-ink)",
              fontSize: 16,
              fontWeight: 700,
              fontFamily: "var(--font-display)",
              boxShadow: "var(--shadow-soft)",
            }}
          >
            M
          </div>
          <div
            style={{
              color: "var(--color-ink)",
              fontSize: 18,
              fontWeight: 600,
              letterSpacing: 0,
              fontFamily: "var(--font-body)",
            }}
          >
            Mavra
          </div>
        </div>

        <div style={{ flex: 1 }} />

        {isMobile ? (
          <Button
            type="text"
            icon={<BarsOutlined />}
            style={{
              color: "var(--color-ink)",
              fontSize: 16,
              border: "1px solid var(--color-border)",
              background: "var(--color-surface)",
              borderRadius: "var(--radius-pill)",
              boxShadow: "none",
            }}
            onClick={() => setDrawerOpen(true)}
            aria-label="Open Menu"
          />
        ) : (
          <>
            <Button
              onClick={toggleTheme}
              style={{
                color: "var(--color-ink)",
                background: "var(--color-butter)",
                border: "1px solid var(--color-border)",
                borderRadius: "var(--radius-pill)",
                boxShadow: "none",
                padding: "4px 12px",
                height: 36,
                fontSize: 15,
                marginRight: 12,
              }}
              aria-label={
                theme === "light"
                  ? "Switch to Dark Mode"
                  : "Switch to Light Mode"
              }
            >
              {theme === "light" ? "🌙 DARK" : "☀️ LIGHT"}
            </Button>

            <Dropdown
              menu={{ items: userMenuItems }}
              trigger={["click"]}
              placement="bottomRight"
            >
              <Button
                style={{
                  color: "var(--color-ink)",
                  height: 36,
                  padding: "4px 12px",
                  background: "var(--color-surface)",
                  border: "1px solid var(--color-border)",
                  borderRadius: "var(--radius-pill)",
                  boxShadow: "none",
                  fontFamily: "var(--font-body)",
                  fontSize: 13,
                  fontWeight: 600,
                  textTransform: "none",
                  marginRight: 12,
                }}
                aria-label="User Menu"
              >
                <Space size={6}>
                  <Avatar
                    size={22}
                    icon={<UserOutlined />}
                    style={{
                      backgroundColor: "#ffffff",
                      color: "var(--color-ink)",
                      fontSize: 11,
                      border: "1px solid var(--color-border)",
                    }}
                  />
                  <span>{user?.username || "User"}</span>
                </Space>
              </Button>
            </Dropdown>

            <Button
              icon={<BarsOutlined style={{ fontSize: 14 }} />}
              style={{
                color: "var(--color-ink)",
                background: "var(--color-surface)",
                border: "1px solid var(--color-border)",
                borderRadius: "var(--radius-pill)",
                boxShadow: "none",
                padding: "4px 12px",
                height: 36,
              }}
              onClick={() => setCollapsed(!collapsed)}
              aria-label={collapsed ? "Expand Sidebar" : "Collapse Sidebar"}
            />
          </>
        )}
      </Layout.Header>

      {/* Desktop Sidebar */}
      {!isMobile && (
        <m.div
          animate={{ width: collapsed ? 60 : 200 }}
          transition={{ type: "spring", stiffness: 200, damping: 25 }}
          style={{
            position: "fixed",
            top: 56,
            left: 0,
            bottom: 48,
            zIndex: 100,
            background: "var(--color-surface-soft)",
            overflow: "hidden",
            borderRadius: "0 var(--radius-lg) var(--radius-lg) 0",
            borderRight: "var(--border-width) solid var(--color-border)",
          }}
        >
          <m.div
            initial={{ opacity: 0, x: -16 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{
              duration: 0.4,
              ease: [0.25, 0.46, 0.45, 0.94],
              delay: 0.1,
            }}
            style={{ width: 200 }}
          >
            <Menu
              mode="inline"
              inlineCollapsed={collapsed}
              selectedKeys={[selectedKey]}
              onClick={handleMenuClick}
              style={{
                border: "none",
                background: "transparent",
                marginTop: 12,
                padding: "0 8px",
              }}
              items={menuItems}
            />
          </m.div>
        </m.div>
      )}

      {/* Mobile Drawer */}
      {isMobile && (
        <Drawer
          placement="left"
          onClose={() => setDrawerOpen(false)}
          open={drawerOpen}
          size={220}
          styles={{
            body: { padding: 0, background: "var(--color-surface-soft)" },
            header: { display: "none" },
          }}
        >
          <m.div
            initial={{ opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.3, delay: 0.05 }}
          >
            <div
              style={{
                padding: "16px",
                borderBottom: "1px solid var(--color-hairline)",
                display: "flex",
                alignItems: "center",
                gap: 10,
              }}
            >
              <div
                style={{
                  width: 28,
                  height: 28,
                  borderRadius: 6,
                  background: "var(--color-primary)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "var(--color-on-primary)",
                  fontSize: 13,
                  fontWeight: 700,
                }}
              >
                M
              </div>
              <span
                style={{
                  fontWeight: 480,
                  fontSize: 15,
                  color: "var(--color-ink)",
                  fontFamily: "var(--font-body)",
                }}
              >
                Mavra
              </span>
            </div>
          </m.div>
          <Menu
            mode="inline"
            selectedKeys={[selectedKey]}
            onClick={handleMenuClick}
            style={{
              border: "none",
              background: "transparent",
              marginTop: 8,
              padding: "0 8px",
            }}
            items={menuItems}
          />
        </Drawer>
      )}

      {/* Main Content */}
      <m.div
        className="app-content"
        animate={{
          marginLeft: isMobile ? 0 : collapsed ? 60 : 200,
        }}
        transition={{
          type: "spring",
          stiffness: 200,
          damping: 25,
        }}
        style={{
          flex: 1,
          marginTop: 56,
          marginBottom: isMobile ? 0 : 48,
          padding: "24px",
          background: "var(--color-canvas)",
          minHeight: isMobile
            ? "calc(100vh - 56px)"
            : "calc(100vh - 104px)",
          overflow: "auto",
          position: "relative",
        }}
      >
        <PageTransition pathname={location.pathname} speed={motionSpeed}>
          {children}
        </PageTransition>
      </m.div>

      {/* Footer */}
      <Layout.Footer
        style={{
          position: isMobile ? "static" : "fixed",
          bottom: 0,
          left: 0,
          right: 0,
          zIndex: 300,
          textAlign: "center",
          padding: "12px 24px",
          height: 48,
          background: "var(--color-canvas)",
          color: "var(--color-ink)",
          fontSize: 12,
          fontFamily: "var(--font-mono)",
          letterSpacing: 0,
          textTransform: "none",
          borderTop: "var(--border-width) solid var(--color-border)",
        }}
      >
        Mavra watches quietly © 2026
      </Layout.Footer>
    </Layout>
  );
}
