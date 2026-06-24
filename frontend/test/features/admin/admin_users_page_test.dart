import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/admin/domain/admin_models.dart';
import 'package:mavra_frontend/features/admin/presentation/admin_users_page.dart';

void main() {
  testWidgets('renders standalone users page without audit logs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(AdminUsersPage(repository: _FakeAdminRepository.full())),
    );
    await tester.pumpAndSettle();

    expect(find.text('System Admin'), findsOneWidget);
    expect(find.text('User Management'), findsOneWidget);
    expect(
      find.text('Manage user accounts, roles, and access permissions'),
      findsOneWidget,
    );
    expect(find.text('Audit Logs'), findsNothing);
    expect(find.byType(MavraResponsiveDataView<AdminUser>), findsOneWidget);
    for (final label in [
      'ID',
      'Username',
      'Email',
      'Status',
      'Registered',
      'Actions',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('Role'), findsWidgets);
    expect(find.text('arfac'), findsOneWidget);
    expect(find.text('Admin'), findsWidgets);
    expect(find.text('Active'), findsWidgets);

    final bannerBottom = tester
        .getBottomLeft(find.byKey(const Key('admin-users-title-banner')))
        .dy;
    final newUserTop = tester
        .getTopLeft(find.byKey(const Key('admin-create-user-button')))
        .dy;
    final searchTop = tester
        .getTopLeft(find.byKey(const Key('admin-user-search-field')))
        .dy;

    expect(newUserTop, greaterThan(bannerBottom));
    expect(searchTop, greaterThan(bannerBottom));
    expect(
      tester
          .getTopLeft(find.byKey(const Key('admin-apply-user-filters-button')))
          .dy,
      tester.getTopLeft(find.byKey(const Key('admin-role-filter'))).dy,
    );
    expect(
      tester
          .getBottomLeft(
            find.byKey(const Key('admin-apply-user-filters-button')),
          )
          .dy,
      tester.getBottomLeft(find.byKey(const Key('admin-role-filter'))).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('admin-create-user-button'))).dy,
      tester.getTopLeft(find.byKey(const Key('admin-role-filter'))).dy,
    );
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('admin-create-user-button')))
          .dy,
      tester.getBottomLeft(find.byKey(const Key('admin-role-filter'))).dy,
    );
  });

  testWidgets('applies search and role filters', (tester) async {
    final repository = _FakeAdminRepository.full();

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('admin-role-tab-admin')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('admin-user-search-field')),
      'arfac',
    );
    await tester.ensureVisible(find.byKey(const Key('admin-role-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-role-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-apply-user-filters-button')));
    await tester.pumpAndSettle();

    expect(repository.lastFilter.search, 'arfac');
    expect(repository.lastFilter.role, 'admin');
  });

  testWidgets('creates and edits user payloads', (tester) async {
    final repository = _FakeAdminRepository.full();

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
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
      find.byKey(const Key('admin-user-password-field')),
      'SecurePass1!',
    );
    await tester.tap(find.byKey(const Key('admin-user-role-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-save-user-button')));
    await tester.pumpAndSettle();

    expect(repository.createdDraft?.username, 'new-user');
    expect(repository.createdDraft?.email, 'new@example.com');
    expect(repository.createdDraft?.password, 'SecurePass1!');
    expect(repository.createdDraft?.role, 'admin');

    await tester.tap(find.byKey(const Key('admin-edit-user-1-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('admin-user-basic-info-tab')), findsOneWidget);
    expect(
      find.byKey(const Key('admin-user-resource-permissions-tab')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('admin-user-email-field')),
      'updated@example.com',
    );
    await tester.tap(find.byKey(const Key('admin-user-active-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-save-user-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedUserId, 1);
    expect(repository.updatedDraft?.email, 'updated@example.com');
    expect(repository.updatedDraft?.active, isFalse);
  });

  testWidgets('gates user actions by permissions', (tester) async {
    await tester.pumpWidget(
      _host(
        AdminUsersPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {'user:read'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-create-user-button')), findsNothing);
    expect(find.byKey(const Key('admin-edit-user-1-button')), findsNothing);
    expect(find.byKey(const Key('admin-delete-user-1-button')), findsNothing);
    expect(find.text('Role Permissions'), findsNothing);

    await tester.pumpWidget(
      _host(
        AdminUsersPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {'user:read', 'user:manage', 'rbac:read'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-create-user-button')), findsOneWidget);
    expect(find.byKey(const Key('admin-edit-user-1-button')), findsOneWidget);
    expect(find.byKey(const Key('admin-delete-user-1-button')), findsNothing);
    expect(find.text('Role Permissions'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('admin-edit-user-2-button')))
          .onPressed,
      isNull,
    );

    await tester.pumpWidget(
      _host(
        AdminUsersPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {
            'user:read',
            'user:manage',
            'user:delete',
            'rbac:read',
            'rbac:manage',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-delete-user-1-button')), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('admin-edit-user-2-button')))
          .onPressed,
      isNotNull,
    );
    expect(find.byKey(const Key('admin-role-admin-user-read')), findsOneWidget);
    expect(
      find.byKey(const Key('admin-save-role-permissions-button')),
      findsOneWidget,
    );
  });

  testWidgets(
    'prevents current and last active super admin destructive actions',
    (tester) async {
      final repository = _FakeAdminRepository.singleSuperAdmin();

      await tester.pumpWidget(
        _host(
          AdminUsersPage(repository: repository, currentUsername: 'default'),
        ),
      );
      await tester.pumpAndSettle();

      final toggle = tester.widget<IconButton>(
        find.byKey(const Key('admin-toggle-user-1-button')),
      );
      final delete = tester.widget<IconButton>(
        find.byKey(const Key('admin-delete-user-1-button')),
      );

      expect(toggle.onPressed, isNull);
      expect(delete.onPressed, isNull);
    },
  );

  testWidgets('shows friendly action failure instead of raw Dio exception', (
    tester,
  ) async {
    final repository = _ToggleFailingAdminRepository();

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-toggle-user-1-button')));
    await tester.pumpAndSettle();

    expect(
      find.text('Action failed: Cannot disable this user'),
      findsOneWidget,
    );
    expect(find.textContaining('DioException'), findsNothing);
  });

  testWidgets('groups role permissions by role tabs with one save action', (
    tester,
  ) async {
    final repository = _FakeAdminRepository.full();

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('admin-role-tab-admin')), findsOneWidget);
    expect(find.byKey(const Key('admin-role-tab-user')), findsOneWidget);
    expect(find.byKey(const Key('admin-role-admin-user-read')), findsOneWidget);
    expect(find.byKey(const Key('admin-role-user-config-read')), findsNothing);
    expect(
      find.byKey(const Key('admin-save-role-permissions-button')),
      findsOneWidget,
    );
    expect(find.text('Save'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('admin-role-tab-user')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-role-tab-user')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('admin-role-user-config-read')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('admin-role-admin-user-read')), findsNothing);

    await tester.tap(find.byKey(const Key('admin-role-user-config-read')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('admin-save-role-permissions-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('admin-save-role-permissions-button')),
    );
    await tester.pumpAndSettle();

    expect(repository.updatedRole, 'user');
    expect(repository.updatedRolePermissions, isNot(contains('config:read')));
  });

  testWidgets('toggle keeps disabled users visible in the table', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _HidingDisabledAdminRepository();

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('admin-toggle-user-1-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-toggle-user-1-button')));
    await tester.pumpAndSettle();

    expect(repository.activeUpdates[1], isFalse);
    expect(find.text('arfac'), findsOneWidget);
    expect(find.text('Disabled'), findsOneWidget);

    await tester.tap(find.byKey(const Key('admin-toggle-user-1-button')));
    await tester.pumpAndSettle();

    expect(repository.activeUpdates[1], isTrue);
    expect(find.text('arfac'), findsOneWidget);
    expect(find.text('Active'), findsWidgets);
  });

  testWidgets(
    'unchecked role permissions remain visible unchecked after save',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repository = _UpdatingRoleAdminRepository();

      await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('admin-role-tab-user')));
      await tester.tap(find.byKey(const Key('admin-role-tab-user')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('admin-role-user-config-read')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('admin-save-role-permissions-button')),
      );
      await tester.pumpAndSettle();

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('admin-role-user-config-read')),
      );
      expect(checkbox.value, isFalse);

      await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('admin-role-tab-user')));
      await tester.tap(find.byKey(const Key('admin-role-tab-user')));
      await tester.pumpAndSettle();

      final reloadedCheckbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('admin-role-user-config-read')),
      );
      expect(reloadedCheckbox.value, isFalse);
    },
  );

  testWidgets('keeps role permission groups compact', (tester) async {
    final repository = _FakeAdminRepository(
      AdminSnapshot(
        users: _FakeAdminRepository.full().snapshot.users,
        rolePermissions: const [
          AdminRolePermission(
            role: 'admin',
            permissions: ['blog:publish', 'crawl:execute'],
          ),
        ],
        auditLogs: const [],
        totalUsers: 2,
        totalAuditLogs: 0,
        permissionsAvailable: true,
        realtime: true,
      ),
    );

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('admin-role-admin-blog-publish')),
    );
    await tester.pumpAndSettle();

    final blogLeft = tester
        .getTopLeft(find.byKey(const Key('admin-role-admin-blog-publish')))
        .dx;
    final crawlLeft = tester
        .getTopLeft(find.byKey(const Key('admin-role-admin-crawl-execute')))
        .dx;

    expect(crawlLeft - blogLeft, lessThan(190));
  });

  testWidgets('manages resource permissions', (tester) async {
    final repository = _FakeAdminRepository.full();

    await tester.pumpWidget(_host(AdminUsersPage(repository: repository)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('admin-edit-user-1-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('admin-user-resource-permissions-tab')),
    );
    await tester.pumpAndSettle();

    expect(find.text('product'), findsWidgets);
    expect(find.text('*'), findsWidgets);
    expect(find.text('read'), findsWidgets);

    await tester.tap(find.byKey(const Key('admin-edit-resource-1-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-resource-id-edit-field')),
      '42',
    );
    await tester.tap(find.byKey(const Key('admin-save-resource-1-button')));
    await tester.pumpAndSettle();
    expect(repository.updatedResourcePermissionId, 1);
    expect(repository.updatedResourceDraft?.resourceId, '42');

    await tester.tap(find.byKey(const Key('admin-revoke-resource-1-button')));
    await tester.pumpAndSettle();
    expect(repository.revokedResourcePermissionId, 1);

    await tester.tap(find.byKey(const Key('admin-grant-resource-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-grant-resource-type-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Job').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('admin-grant-resource-ids-field')),
      '12, 13',
    );
    await tester.tap(find.byKey(const Key('admin-grant-permission-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Write').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('admin-confirm-grant-button')));
    await tester.pumpAndSettle();

    expect(repository.grantedResourceDraft?.subjectId, 1);
    expect(repository.grantedResourceDraft?.resourceType, 'job');
    expect(repository.grantedResourceDraft?.resourceIds, ['12', '13']);
    expect(repository.grantedResourceDraft?.permission, 'write');
  });

  testWidgets('renders loading, empty, error, and permission denied states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AdminUsersPage(repository: _SlowAdminRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载用户管理数据...'), findsOneWidget);

    await tester.pumpWidget(
      _host(AdminUsersPage(repository: _FakeAdminRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('User Management'), findsOneWidget);
    expect(find.text('没有符合条件的用户。'), findsOneWidget);

    await tester.pumpWidget(
      _host(AdminUsersPage(repository: _FailingAdminRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('用户管理数据加载失败。'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        AdminUsersPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有权限访问用户管理。'), findsOneWidget);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Material(child: child),
  );
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository(this.snapshot);

  factory _FakeAdminRepository.full() => _FakeAdminRepository(
    AdminSnapshot(
      users: [
        AdminUser(
          id: 1,
          username: 'arfac',
          email: 'admin@example.com',
          role: 'admin',
          active: true,
          createdAt: DateTime.utc(2026, 6, 16, 9, 30),
        ),
        AdminUser(
          id: 2,
          username: 'root',
          email: 'root@example.com',
          role: 'super_admin',
          active: true,
          createdAt: DateTime.utc(2026, 6, 15),
        ),
      ],
      rolePermissions: const [
        AdminRolePermission(
          role: 'admin',
          permissions: ['user:read', 'user:manage'],
          availablePermissions: ['config:read', 'user:read', 'user:manage'],
        ),
        AdminRolePermission(
          role: 'user',
          permissions: ['config:read'],
          availablePermissions: ['config:read', 'user:read', 'user:manage'],
        ),
      ],
      auditLogs: const [],
      totalUsers: 2,
      totalAuditLogs: 0,
      permissionsAvailable: true,
      realtime: true,
      resourcePermissions: [
        ResourcePermissionItem(
          id: 1,
          resourceType: 'product',
          resourceId: '*',
          permission: 'read',
          subjectId: 1,
          createdAt: DateTime.utc(2026, 6, 17),
        ),
      ],
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
      realtime: true,
    ),
  );

  factory _FakeAdminRepository.singleSuperAdmin() => _FakeAdminRepository(
    AdminSnapshot(
      users: [
        AdminUser(
          id: 1,
          username: 'default',
          email: 'default@localhost.com',
          role: 'super_admin',
          active: true,
          createdAt: DateTime.utc(2026, 4, 22, 5, 10),
        ),
      ],
      rolePermissions: const [],
      auditLogs: const [],
      totalUsers: 1,
      totalAuditLogs: 0,
      permissionsAvailable: true,
      realtime: true,
    ),
  );

  AdminSnapshot snapshot;
  AdminFilter lastFilter = const AdminFilter();
  AdminUserDraft? createdDraft;
  int? updatedUserId;
  AdminUserDraft? updatedDraft;
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
    return snapshot.resourcePermissions
        .where((permission) => userId == null || permission.subjectId == userId)
        .toList();
  }

  @override
  Future<List<ResourcePermissionItem>> grantResourcePermissions(
    ResourcePermissionGrantDraft draft,
  ) async {
    grantedResourceDraft = draft;
    return listResourcePermissions(userId: draft.subjectId);
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
      subjectId: 1,
      createdAt: DateTime.utc(2026, 6, 17),
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
  Future<void> setUserActive(int userId, bool active) async {}

  @override
  Future<void> deleteUser(int userId) async {}
}

class _HidingDisabledAdminRepository extends _FakeAdminRepository {
  _HidingDisabledAdminRepository()
    : super(_FakeAdminRepository.full().snapshot);

  final activeUpdates = <int, bool>{};

  @override
  Future<void> setUserActive(int userId, bool active) async {
    activeUpdates[userId] = active;
    snapshot = AdminSnapshot(
      users: [
        for (final user in snapshot.users)
          if (user.id != userId) user,
      ],
      rolePermissions: snapshot.rolePermissions,
      auditLogs: snapshot.auditLogs,
      totalUsers: snapshot.totalUsers,
      totalAuditLogs: snapshot.totalAuditLogs,
      permissionsAvailable: snapshot.permissionsAvailable,
      realtime: snapshot.realtime,
      resourcePermissions: snapshot.resourcePermissions,
    );
  }
}

class _UpdatingRoleAdminRepository extends _FakeAdminRepository {
  _UpdatingRoleAdminRepository() : super(_FakeAdminRepository.full().snapshot);

  @override
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {
    await super.updateRolePermissions(role: role, permissions: permissions);
    snapshot = AdminSnapshot(
      users: snapshot.users,
      rolePermissions: [
        for (final item in snapshot.rolePermissions)
          if (item.role == role)
            AdminRolePermission(role: role, permissions: permissions)
          else
            item,
      ],
      auditLogs: snapshot.auditLogs,
      totalUsers: snapshot.totalUsers,
      totalAuditLogs: snapshot.totalAuditLogs,
      permissionsAvailable: snapshot.permissionsAvailable,
      realtime: snapshot.realtime,
      resourcePermissions: snapshot.resourcePermissions,
    );
  }
}

class _ToggleFailingAdminRepository extends _FakeAdminRepository {
  _ToggleFailingAdminRepository() : super(_FakeAdminRepository.full().snapshot);

  @override
  Future<void> setUserActive(int userId, bool active) {
    final requestOptions = RequestOptions(path: '/admin/users/$userId');
    throw DioException(
      requestOptions: requestOptions,
      response: Response<Map<String, Object?>>(
        requestOptions: requestOptions,
        statusCode: 400,
        data: const {'detail': 'Cannot disable this user'},
      ),
    );
  }
}

class _SlowAdminRepository extends _FakeAdminRepository {
  _SlowAdminRepository() : super(const AdminSnapshot.empty());

  final _completer = Completer<AdminSnapshot>();

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) => _completer.future;
}

class _FailingAdminRepository extends _FakeAdminRepository {
  _FailingAdminRepository() : super(const AdminSnapshot.empty());

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) {
    throw StateError('boom');
  }
}
