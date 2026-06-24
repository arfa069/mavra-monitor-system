import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
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
    final resourcePermissionsResponse = await _adminApi
        .adminListResourcePermissions(pageSize: 50);

    final users = usersResponse.data;
    final matrix = matrixResponse?.data;
    final allRolePermissions = <String>[
      for (final permission in matrix?.allPermissions.toList() ?? const [])
        permission.name,
    ];
    final audits = auditsResponse.data;
    final resourcePermissions = resourcePermissionsResponse.data;

    return AdminSnapshot(
      users: [
        for (final user in users?.items.toList() ?? const []) _mapUser(user),
      ],
      rolePermissions: [
        for (final role in matrix?.roles.toList() ?? const [])
          _mapRole(role, allRolePermissions),
      ],
      auditLogs: [
        for (final log in audits?.items.toList() ?? const []) _mapAudit(log),
      ],
      totalUsers: users?.total ?? 0,
      totalAuditLogs: audits?.total ?? 0,
      permissionsAvailable: matrix != null,
      realtime: false,
      resourcePermissions: [
        for (final permission
            in resourcePermissions?.items.toList() ?? const [])
          _mapResourcePermission(permission),
      ],
    );
  }

  @override
  Future<List<AdminUser>> listUsers(AdminFilter filter) async {
    final response = await _adminApi.adminListUsers(
      page: filter.userPage,
      pageSize: filter.pageSize,
      search: filter.search,
      role: filter.role,
    );
    return [
      for (final user in response.data?.items.toList() ?? const [])
        _mapUser(user),
    ];
  }

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) async {
    final response = await _adminApi.adminListAuditLogs(
      page: filter.auditPage,
      pageSize: filter.pageSize,
      actorUserId: filter.auditActorUserId,
      action: filter.auditAction,
    );
    final data = response.data;
    return AuditLogPageState(
      items: [
        for (final log in data?.items.toList() ?? const []) _mapAudit(log),
      ],
      page: data?.page ?? filter.auditPage,
      pageSize: data?.pageSize ?? filter.pageSize,
      total: data?.total ?? 0,
    );
  }

  @override
  Future<List<AdminRolePermission>> loadRolePermissionMatrix() async {
    final response = await _adminApi.adminGetRolePermissionMatrix();
    final allRolePermissions = <String>[
      for (final permission in response.data?.allPermissions.toList() ?? const [])
        permission.name,
    ];
    return [
      for (final role in response.data?.roles.toList() ?? const [])
        _mapRole(role, allRolePermissions),
    ];
  }

  @override
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {
    await _adminApi.adminUpdateRolePermissions(
      roleName: role,
      rolePermissionUpdate: generated.RolePermissionUpdate(
        (builder) => builder.permissions.replace(permissions),
      ),
    );
  }

  @override
  Future<List<ResourcePermissionItem>> listResourcePermissions({
    int? userId,
    String? resourceType,
  }) async {
    final response = await _adminApi.adminListResourcePermissions(
      userId: userId,
      resourceType: resourceType,
      pageSize: 50,
    );
    return [
      for (final permission in response.data?.items.toList() ?? const [])
        _mapResourcePermission(permission),
    ];
  }

  @override
  Future<List<ResourcePermissionItem>> grantResourcePermissions(
    ResourcePermissionGrantDraft draft,
  ) async {
    await _adminApi.adminGrantResourcePermission(
      resourcePermissionGrant: generated.ResourcePermissionGrant(
        (builder) => builder
          ..subjectId = draft.subjectId
          ..resourceType = draft.resourceType
          ..resourceIds.replace(draft.resourceIds)
          ..permission = draft.permission,
      ),
    );
    return listResourcePermissions(
      userId: draft.subjectId,
      resourceType: draft.resourceType,
    );
  }

  @override
  Future<ResourcePermissionItem> updateResourcePermission(
    int permissionId,
    ResourcePermissionUpdateDraft draft,
  ) async {
    final response = await _adminApi.adminUpdateResourcePermission(
      permissionId: permissionId,
      resourcePermissionUpdate: generated.ResourcePermissionUpdate(
        (builder) => builder
          ..resourceType = draft.resourceType
          ..resourceId = draft.resourceId
          ..permission = draft.permission,
      ),
    );
    final permission = response.data;
    if (permission == null) {
      throw StateError('Resource permission #$permissionId was not returned.');
    }
    return _mapResourcePermission(permission);
  }

  @override
  Future<void> revokeResourcePermission(int permissionId) async {
    await _adminApi.adminRevokeResourcePermission(permissionId: permissionId);
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

  static AdminUser _mapUser(generated.AdminUserResponse user) {
    return AdminUser(
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      active: user.isActive ?? true,
      createdAt: user.createdAt,
    );
  }

  static AdminRolePermission _mapRole(
    generated.RolePermissionResponse role,
    List<String> availablePermissions,
  ) {
    return AdminRolePermission(
      role: role.role,
      permissions: role.permissions.toList(),
      availablePermissions: availablePermissions,
    );
  }

  static AdminAuditLog _mapAudit(generated.AuditLogResponse log) {
    return AdminAuditLog(
      id: log.id,
      action: log.action,
      actorUserId: log.actorUserId,
      targetType: log.targetType,
      targetId: log.targetId,
      createdAt: log.createdAt,
      details: _mapAuditDetails(log.details),
      ipAddress: log.ipAddress,
    );
  }

  static Map<String, Object?>? _mapAuditDetails(
    BuiltMap<String, JsonObject?>? details,
  ) {
    if (details == null || details.isEmpty) {
      return null;
    }
    return {
      for (final entry in details.entries)
        entry.key: _jsonValue(entry.value?.value),
    };
  }

  static Object? _jsonValue(Object? value) {
    if (value is Map) {
      return {
        for (final entry in value.entries)
          entry.key.toString(): _jsonValue(entry.value),
      };
    }
    if (value is Iterable) {
      return [for (final item in value) _jsonValue(item)];
    }
    return value;
  }

  static ResourcePermissionItem _mapResourcePermission(
    generated.ResourcePermissionResponse permission,
  ) {
    return ResourcePermissionItem(
      id: permission.id,
      resourceType: permission.resourceType,
      resourceId: permission.resourceId,
      permission: permission.permission,
      createdAt: permission.createdAt,
      subjectId: permission.subjectId,
    );
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
