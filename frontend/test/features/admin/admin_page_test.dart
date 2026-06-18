import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/features/admin/domain/admin_models.dart';
import 'package:mavra_frontend/features/admin/presentation/admin_page.dart';

void main() {
  testWidgets('renders users, permission matrix, and audit logs', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AdminPage(repository: _FakeAdminRepository.full())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Users'), findsOneWidget);
    expect(find.text('arfac'), findsOneWidget);
    expect(find.text('admin@example.com'), findsOneWidget);
    expect(find.text('super_admin'), findsOneWidget);
    expect(find.text('active'), findsOneWidget);
    expect(find.text('Permission matrix'), findsOneWidget);
    expect(find.text('admin'), findsOneWidget);
    expect(find.text('user:read'), findsOneWidget);
    expect(find.text('Audit Logs'), findsOneWidget);
    expect(find.text('user.login'), findsOneWidget);
    expect(find.text('actor #1'), findsOneWidget);
  });

  testWidgets('applies user and audit filters', (tester) async {
    final repository = _FakeAdminRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: AdminPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-user-search-field')),
      'admin',
    );
    await tester.enterText(
      find.byKey(const Key('admin-audit-action-field')),
      'user.login',
    );
    await tester.enterText(
      find.byKey(const Key('admin-role-field')),
      'super_admin',
    );
    await tester.enterText(
      find.byKey(const Key('admin-audit-actor-field')),
      '1',
    );
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(repository.lastFilter.search, 'admin');
    expect(repository.lastFilter.auditAction, 'user.login');
    expect(repository.lastFilter.role, 'super_admin');
    expect(repository.lastFilter.auditActorUserId, 1);
  });

  testWidgets('creates, edits, disables, deletes, and pages users and audits', (
    tester,
  ) async {
    final repository = _FakeAdminRepository.full(totalUsers: 40);

    await tester.pumpWidget(
      MaterialApp(home: AdminPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-create-user-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-user-username-field')),
      'new-user',
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-email-field')),
      'new@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-role-field')),
      'admin',
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-password-field')),
      'password123',
    );
    await tester.tap(find.byKey(const Key('admin-save-user-button')));
    await tester.pumpAndSettle();
    expect(repository.createdDraft?.username, 'new-user');

    await tester.ensureVisible(
      find.byKey(const Key('admin-edit-user-1-button')),
    );
    await tester.tap(find.byKey(const Key('admin-edit-user-1-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-user-role-field')),
      'operator',
    );
    await tester.tap(find.byKey(const Key('admin-save-user-button')));
    await tester.pumpAndSettle();
    expect(repository.updatedUserId, 1);
    expect(repository.updatedDraft?.role, 'operator');

    await tester.ensureVisible(
      find.byKey(const Key('admin-toggle-user-1-button')),
    );
    await tester.tap(find.byKey(const Key('admin-toggle-user-1-button')));
    await tester.pumpAndSettle();
    expect(repository.toggledUserId, 1);
    expect(repository.toggledActive, isFalse);

    await tester.ensureVisible(
      find.byKey(const Key('admin-delete-user-1-button')),
    );
    await tester.tap(find.byKey(const Key('admin-delete-user-1-button')));
    await tester.pumpAndSettle();
    expect(repository.deletedUserId, 1);

    await tester.ensureVisible(
      find.byKey(const Key('admin-users-next-page-button')),
    );
    await tester.tap(find.byKey(const Key('admin-users-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastFilter.userPage, 2);

    await tester.ensureVisible(
      find.byKey(const Key('admin-audits-next-page-button')),
    );
    await tester.tap(find.byKey(const Key('admin-audits-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastFilter.auditPage, 2);
  });

  testWidgets('uses permission strings for access and row actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有权限访问管理功能。'), findsOneWidget);
    expect(find.text('回到 Today'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {'user:read'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('arfac'), findsOneWidget);
    expect(find.text('Manage arfac'), findsNothing);
    expect(find.text('Permission matrix'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {'user:read', 'user:manage'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage arfac'), findsOneWidget);
  });

  testWidgets('renders loading, empty, and error states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AdminPage(repository: _SlowAdminRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载管理数据...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: AdminPage(repository: _FakeAdminRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('没有符合条件的记录。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: AdminPage(repository: _FailingAdminRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('管理数据加载失败。'), findsOneWidget);
  });
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository(this.snapshot);

  factory _FakeAdminRepository.full({int totalUsers = 1}) =>
      _FakeAdminRepository(
        AdminSnapshot(
          users: [
            AdminUser(
              id: 1,
              username: 'arfac',
              email: 'admin@example.com',
              role: 'super_admin',
              active: true,
              createdAt: DateTime.utc(2026, 6, 16),
            ),
          ],
          rolePermissions: const [
            AdminRolePermission(
              role: 'admin',
              permissions: ['user:read', 'user:manage'],
            ),
          ],
          auditLogs: [
            AdminAuditLog(
              id: 11,
              action: 'user.login',
              actorUserId: 1,
              targetType: 'session',
              targetId: null,
              createdAt: DateTime.utc(2026, 6, 16, 9),
            ),
          ],
          totalUsers: totalUsers,
          totalAuditLogs: 40,
          permissionsAvailable: true,
          realtime: false,
        ),
      );

  factory _FakeAdminRepository.empty() => _FakeAdminRepository(
    const AdminSnapshot(
      users: [],
      rolePermissions: [],
      auditLogs: [],
      totalUsers: 0,
      totalAuditLogs: 0,
      permissionsAvailable: true,
      realtime: false,
    ),
  );

  final AdminSnapshot snapshot;
  AdminFilter lastFilter = const AdminFilter();
  AdminUserDraft? createdDraft;
  AdminUserDraft? updatedDraft;
  int? updatedUserId;
  int? toggledUserId;
  bool? toggledActive;
  int? deletedUserId;
  String? updatedRole;
  List<String>? updatedRolePermissions;
  ResourcePermissionGrantDraft? grantedResourceDraft;
  int? updatedResourcePermissionId;
  ResourcePermissionUpdateDraft? updatedResourceDraft;
  int? revokedResourcePermissionId;

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) async {
    lastFilter = filter;
    return snapshot;
  }

  @override
  Future<List<AdminUser>> listUsers(AdminFilter filter) async {
    lastFilter = filter;
    return snapshot.users;
  }

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) async {
    lastFilter = filter;
    return AuditLogPageState(
      items: snapshot.auditLogs,
      page: filter.auditPage,
      pageSize: filter.pageSize,
      total: snapshot.totalAuditLogs,
    );
  }

  @override
  Future<List<AdminRolePermission>> loadRolePermissionMatrix() async {
    return snapshot.rolePermissions;
  }

  @override
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {
    updatedRole = role;
    updatedRolePermissions = permissions;
  }

  @override
  Future<List<ResourcePermissionItem>> listResourcePermissions({
    int? userId,
    String? resourceType,
  }) async {
    return snapshot.resourcePermissions;
  }

  @override
  Future<List<ResourcePermissionItem>> grantResourcePermissions(
    ResourcePermissionGrantDraft draft,
  ) async {
    grantedResourceDraft = draft;
    return snapshot.resourcePermissions;
  }

  @override
  Future<ResourcePermissionItem> updateResourcePermission(
    int permissionId,
    ResourcePermissionUpdateDraft draft,
  ) async {
    updatedResourcePermissionId = permissionId;
    updatedResourceDraft = draft;
    return ResourcePermissionItem(
      id: permissionId,
      resourceType: draft.resourceType ?? 'product',
      resourceId: draft.resourceId ?? '*',
      permission: draft.permission ?? 'read',
      createdAt: DateTime.utc(2026, 6, 16),
    );
  }

  @override
  Future<void> revokeResourcePermission(int permissionId) async {
    revokedResourcePermissionId = permissionId;
  }

  @override
  Future<void> createUser(AdminUserDraft draft) async {
    createdDraft = draft;
  }

  @override
  Future<void> updateUser(int userId, AdminUserDraft draft) async {
    updatedUserId = userId;
    updatedDraft = draft;
  }

  @override
  Future<void> setUserActive(int userId, bool active) async {
    toggledUserId = userId;
    toggledActive = active;
  }

  @override
  Future<void> deleteUser(int userId) async {
    deletedUserId = userId;
  }
}

class _SlowAdminRepository implements AdminRepository {
  final _completer = Completer<AdminSnapshot>();

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) => _completer.future;

  @override
  Future<List<AdminUser>> listUsers(AdminFilter filter) async => const [];

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) async {
    return AuditLogPageState(
      items: const [],
      page: filter.auditPage,
      pageSize: filter.pageSize,
      total: 0,
    );
  }

  @override
  Future<List<AdminRolePermission>> loadRolePermissionMatrix() async =>
      const [];

  @override
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {}

  @override
  Future<List<ResourcePermissionItem>> listResourcePermissions({
    int? userId,
    String? resourceType,
  }) async => const [];

  @override
  Future<List<ResourcePermissionItem>> grantResourcePermissions(
    ResourcePermissionGrantDraft draft,
  ) async => const [];

  @override
  Future<ResourcePermissionItem> updateResourcePermission(
    int permissionId,
    ResourcePermissionUpdateDraft draft,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<void> revokeResourcePermission(int permissionId) async {}

  @override
  Future<void> createUser(AdminUserDraft draft) async {}

  @override
  Future<void> updateUser(int userId, AdminUserDraft draft) async {}

  @override
  Future<void> setUserActive(int userId, bool active) async {}

  @override
  Future<void> deleteUser(int userId) async {}
}

class _FailingAdminRepository implements AdminRepository {
  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) {
    throw StateError('admin down');
  }

  @override
  Future<List<AdminUser>> listUsers(AdminFilter filter) async {
    throw StateError('admin down');
  }

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) async {
    throw StateError('admin down');
  }

  @override
  Future<List<AdminRolePermission>> loadRolePermissionMatrix() async =>
      const [];

  @override
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {}

  @override
  Future<List<ResourcePermissionItem>> listResourcePermissions({
    int? userId,
    String? resourceType,
  }) async => const [];

  @override
  Future<List<ResourcePermissionItem>> grantResourcePermissions(
    ResourcePermissionGrantDraft draft,
  ) async => const [];

  @override
  Future<ResourcePermissionItem> updateResourcePermission(
    int permissionId,
    ResourcePermissionUpdateDraft draft,
  ) async {
    throw StateError('admin down');
  }

  @override
  Future<void> revokeResourcePermission(int permissionId) async {}

  @override
  Future<void> createUser(AdminUserDraft draft) async {}

  @override
  Future<void> updateUser(int userId, AdminUserDraft draft) async {}

  @override
  Future<void> setUserActive(int userId, bool active) async {}

  @override
  Future<void> deleteUser(int userId) async {}
}
