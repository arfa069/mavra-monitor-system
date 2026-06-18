import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../domain/admin_models.dart';

class GeneratedAdminRepository implements AdminRepository {
  GeneratedAdminRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.AdminApi get _adminApi => _client.getAdminApi();

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) async {
    final usersResponse = await _adminApi.adminListUsers(
      page: filter.userPage,
      pageSize: filter.pageSize,
      search: filter.search,
      role: filter.role,
    );
    final auditsResponse = await _adminApi.adminListAuditLogs(
      page: filter.auditPage,
      pageSize: filter.pageSize,
      actorUserId: filter.auditActorUserId,
      action: filter.auditAction,
    );
    final matrixResponse = filter.includeRolePermissions
        ? await _adminApi.adminGetRolePermissionMatrix()
        : null;

    final users = usersResponse.data;
    final matrix = matrixResponse?.data;
    final audits = auditsResponse.data;

    return AdminSnapshot(
      users: [
        for (final user in users?.items.toList() ?? const [])
          AdminUser(
            id: user.id,
            username: user.username,
            email: user.email,
            role: user.role,
            active: user.isActive ?? true,
            createdAt: user.createdAt,
          ),
      ],
      rolePermissions: [
        for (final role in matrix?.roles.toList() ?? const [])
          AdminRolePermission(
            role: role.role,
            permissions: role.permissions.toList(),
          ),
      ],
      auditLogs: [
        for (final log in audits?.items.toList() ?? const [])
          AdminAuditLog(
            id: log.id,
            action: log.action,
            actorUserId: log.actorUserId,
            targetType: log.targetType,
            targetId: log.targetId,
            createdAt: log.createdAt,
          ),
      ],
      totalUsers: users?.total ?? 0,
      totalAuditLogs: audits?.total ?? 0,
      permissionsAvailable: matrix != null,
      realtime: false,
    );
  }

  @override
  Future<void> createUser(AdminUserDraft draft) async {
    await _adminApi.adminCreateUser(
      userCreate: generated.UserCreate(
        (builder) => builder
          ..username = draft.username
          ..email = draft.email
          ..password = draft.password ?? ''
          ..role = draft.role,
      ),
    );
  }

  @override
  Future<void> updateUser(int userId, AdminUserDraft draft) async {
    await _adminApi.adminUpdateUser(
      userId: userId,
      adminUserUpdate: generated.AdminUserUpdate(
        (builder) => builder
          ..username = draft.username
          ..email = draft.email
          ..role = draft.role
          ..isActive = draft.active,
      ),
    );
  }

  @override
  Future<void> setUserActive(int userId, bool active) async {
    await _adminApi.adminUpdateUser(
      userId: userId,
      adminUserUpdate: generated.AdminUserUpdate(
        (builder) => builder.isActive = active,
      ),
    );
  }

  @override
  Future<void> deleteUser(int userId) async {
    await _adminApi.adminDeleteUser(userId: userId);
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
