import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/admin/domain/admin_models.dart';
import 'package:mavra_frontend/features/admin/presentation/admin_audit_logs_page.dart';

void main() {
  testWidgets('renders standalone audit logs page without users content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AdminAuditLogsPage(repository: _FakeAdminRepository.full())),
    );
    await tester.pumpAndSettle();

    expect(find.text('System Admin'), findsOneWidget);
    expect(find.text('Audit Logs'), findsOneWidget);
    expect(find.text('View system operation audit records'), findsOneWidget);
    expect(find.text('User Management'), findsNothing);
    expect(find.text('Role Permissions'), findsNothing);
    expect(find.byKey(const Key('admin-create-user-button')), findsNothing);
    expect(find.byKey(const Key('admin-audit-action-field')), findsNothing);
    expect(find.byKey(const Key('admin-audit-actor-field')), findsNothing);
    expect(find.byType(MavraResponsiveDataView<AdminAuditLog>), findsOneWidget);

    for (final label in [
      'ID',
      'Action',
      'Actor ID',
      'Target Type',
      'Target ID',
      'Details',
      'IP Address',
      'Time',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets(
    'shows action labels, details json, ip address, and null fallbacks',
    (tester) async {
      await tester.pumpWidget(
        _host(AdminAuditLogsPage(repository: _FakeAdminRepository.full())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Create User'), findsOneWidget);
      expect(
        find.byKey(const Key('admin-audit-action-chip-101')),
        findsOneWidget,
      );
      expect(
        find.textContaining('"email": "admin@example.com"'),
        findsOneWidget,
      );
      expect(find.text('192.0.2.10'), findsOneWidget);
      expect(find.text('2026-06-17 09:10'), findsOneWidget);

      expect(find.text('unknown.action'), findsOneWidget);
      expect(
        find.byKey(const Key('admin-audit-action-chip-102')),
        findsOneWidget,
      );
      expect(find.text('203.0.113.3'), findsOneWidget);
      expect(find.text('-'), findsWidgets);
    },
  );

  testWidgets('changes audit page and page size through repository filters', (
    tester,
  ) async {
    final repository = _FakeAdminRepository.full(total: 60);

    await tester.pumpWidget(_host(AdminAuditLogsPage(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Total 60 records'), findsOneWidget);
    await tester.tap(find.byKey(const Key('admin-audits-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastFilter.auditPage, 2);
    expect(repository.lastFilter.pageSize, 20);
    expect(repository.lastFilter.auditAction, isNull);
    expect(repository.lastFilter.auditActorUserId, isNull);

    await tester.tap(find.byKey(const Key('admin-audit-page-size-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 / page').last);
    await tester.pumpAndSettle();

    expect(repository.lastFilter.auditPage, 1);
    expect(repository.lastFilter.pageSize, 50);
  });

  testWidgets('renders loading, empty, error, and permission denied states', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(AdminAuditLogsPage(repository: _SlowAdminRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载审计日志...'), findsOneWidget);

    await tester.pumpWidget(
      _host(AdminAuditLogsPage(repository: _FakeAdminRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Audit Logs'), findsOneWidget);
    expect(find.text('没有审计日志。'), findsOneWidget);

    await tester.pumpWidget(
      _host(AdminAuditLogsPage(repository: _FailingAdminRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('审计日志加载失败。'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        AdminAuditLogsPage(
          repository: _FakeAdminRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有权限访问审计日志。'), findsOneWidget);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Material(child: child),
  );
}

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository(this.pageState);

  factory _FakeAdminRepository.full({int total = 2}) => _FakeAdminRepository(
    AuditLogPageState(
      items: [
        AdminAuditLog(
          id: 101,
          action: 'user.create',
          actorUserId: 1,
          targetType: 'user',
          targetId: 42,
          details: const {'email': 'admin@example.com', 'role': 'admin'},
          ipAddress: '192.0.2.10',
          createdAt: DateTime.utc(2026, 6, 17, 9, 10),
        ),
        AdminAuditLog(
          id: 102,
          action: 'unknown.action',
          actorUserId: null,
          targetType: null,
          targetId: null,
          details: null,
          ipAddress: '203.0.113.3',
          createdAt: DateTime.utc(2026, 6, 17, 9, 20),
        ),
      ],
      page: 1,
      pageSize: 20,
      total: total,
    ),
  );

  factory _FakeAdminRepository.empty() => _FakeAdminRepository(
    const AuditLogPageState(items: [], page: 1, pageSize: 20, total: 0),
  );

  AuditLogPageState pageState;
  AdminFilter lastFilter = const AdminFilter();

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) async {
    lastFilter = filter;
    pageState = AuditLogPageState(
      items: pageState.items,
      page: filter.auditPage,
      pageSize: filter.pageSize,
      total: pageState.total,
    );
    return pageState;
  }

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) async {
    lastFilter = filter;
    return AdminSnapshot(
      users: const [],
      rolePermissions: const [],
      auditLogs: pageState.items,
      totalUsers: 0,
      totalAuditLogs: pageState.total,
      permissionsAvailable: true,
      realtime: true,
    );
  }

  @override
  Future<List<AdminUser>> listUsers(AdminFilter filter) async => const [];

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

class _SlowAdminRepository extends _FakeAdminRepository {
  _SlowAdminRepository()
    : super(
        const AuditLogPageState(items: [], page: 1, pageSize: 20, total: 0),
      );

  final _completer = Completer<AuditLogPageState>();

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) {
    lastFilter = filter;
    return _completer.future;
  }
}

class _FailingAdminRepository extends _FakeAdminRepository {
  _FailingAdminRepository()
    : super(
        const AuditLogPageState(items: [], page: 1, pageSize: 20, total: 0),
      );

  @override
  Future<AuditLogPageState> listAuditLogs(AdminFilter filter) {
    throw StateError('audit down');
  }
}
