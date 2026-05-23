import {
  createContext,
  useContext,
  useState,
  useEffect,
  type ReactNode,
} from "react";
import { authApi } from "@/features/auth";
import type { Permission, User } from "@/shared/types";

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAuthenticated: boolean;
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

  const login = (userData: User) => {
    setUser(userData);
  };

  const logout = async () => {
    try {
      await authApi.logout();
    } catch {
      // Best-effort: cookies cleared server-side
    }
    setUser(null);
  };

  const hasPermission = (permission: Permission) =>
    Boolean(user?.permissions?.includes(permission));

  const hasAnyPermission = (permissions: Permission[]) =>
    permissions.some((permission) => hasPermission(permission));

  const hasAllPermissions = (permissions: Permission[]) =>
    permissions.every((permission) => hasPermission(permission));

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        login,
        logout,
        hasPermission,
        hasAnyPermission,
        hasAllPermissions,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
}

// eslint-disable-next-line react-refresh/only-export-components
export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
