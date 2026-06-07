import {
  createContext,
  useContext,
  useState,
  useEffect,
  useCallback,
  useMemo,
  type ReactNode,
} from "react";
import { authApi } from "@/features/auth/api/auth";
import type { Permission, User } from "@/shared/types";

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
  isAdmin: boolean;
  login: (user: User) => void;
  logout: () => void;
  hasPermission: (permission: Permission) => boolean;
  hasAnyPermission: (permissions: Permission[]) => boolean;
  hasAllPermissions: (permissions: Permission[]) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  // Restore auth state from server on init
  useEffect(() => {
    const initAuth = async () => {
      try {
        const response = await authApi.getMe();
        setUser(response.data);
      } catch {
        setUser(null);
      }
      setIsLoading(false);
    };

    initAuth();
  }, []);

  const login = useCallback((userData: User) => {
    setUser(userData);
  }, []);

  const logout = useCallback(async () => {
    try {
      await authApi.logout();
    } catch {
      // Best-effort: cookies cleared server-side
    }
    setUser(null);
  }, []);

  const hasPermission = useCallback(
    (permission: Permission) =>
      Boolean(user?.permissions?.includes(permission)),
    [user],
  );

  const hasAnyPermission = useCallback(
    (permissions: Permission[]) =>
      permissions.some((permission) => hasPermission(permission)),
    [hasPermission],
  );

  const hasAllPermissions = useCallback(
    (permissions: Permission[]) =>
      permissions.every((permission) => hasPermission(permission)),
    [hasPermission],
  );

  const isAdmin = user?.role === "admin" || user?.role === "super_admin";

  const value = useMemo(
    () => ({
      user,
      isLoading,
      isAuthenticated: !!user,
      isAdmin,
      login,
      logout,
      hasPermission,
      hasAnyPermission,
      hasAllPermissions,
    }),
    [
      user,
      isLoading,
      isAdmin,
      login,
      logout,
      hasPermission,
      hasAnyPermission,
      hasAllPermissions,
    ],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
