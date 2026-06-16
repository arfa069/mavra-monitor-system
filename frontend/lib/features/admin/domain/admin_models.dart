class AdminUser {
  const AdminUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
  });

  final int id;
  final String username;
  final String email;
  final String role;
  final bool active;
  final DateTime createdAt;
}

class AdminRolePermission {
  const AdminRolePermission({required this.role, required this.permissions});

  final String role;
  final List<String> permissions;
}

class AdminAuditLog {
  const AdminAuditLog({
    required this.id,
    required this.action,
    required this.actorUserId,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  final int id;
  final String action;
  final int? actorUserId;
  final String? targetType;
  final int? targetId;
  final DateTime createdAt;
}

class AdminSnapshot {
  const AdminSnapshot({
    required this.users,
    required this.rolePermissions,
    required this.auditLogs,
    required this.totalUsers,
    required this.totalAuditLogs,
    required this.permissionsAvailable,
    required this.realtime,
  });

  const AdminSnapshot.empty()
    : users = const [],
      rolePermissions = const [],
      auditLogs = const [],
      totalUsers = 0,
      totalAuditLogs = 0,
      permissionsAvailable = true,
      realtime = false;

  final List<AdminUser> users;
  final List<AdminRolePermission> rolePermissions;
  final List<AdminAuditLog> auditLogs;
  final int totalUsers;
  final int totalAuditLogs;
  final bool permissionsAvailable;
  final bool realtime;

  bool get isEmpty =>
      users.isEmpty && rolePermissions.isEmpty && auditLogs.isEmpty;
}

class AdminFilter {
  const AdminFilter({
    this.search,
    this.role,
    this.auditAction,
    this.includeRolePermissions = true,
  });

  final String? search;
  final String? role;
  final String? auditAction;
  final bool includeRolePermissions;
}

abstract class AdminRepository {
  Future<AdminSnapshot> loadAdmin(AdminFilter filter);
}
