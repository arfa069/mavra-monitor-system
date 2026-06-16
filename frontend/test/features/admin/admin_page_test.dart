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
    await tester.tap(find.text('Apply filters'));
    await tester.pumpAndSettle();

    expect(repository.lastFilter.search, 'admin');
    expect(repository.lastFilter.auditAction, 'user.login');
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

  factory _FakeAdminRepository.full() => _FakeAdminRepository(
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
      totalUsers: 1,
      totalAuditLogs: 1,
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

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) async {
    lastFilter = filter;
    return snapshot;
  }
}

class _SlowAdminRepository implements AdminRepository {
  final _completer = Completer<AdminSnapshot>();

  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) => _completer.future;
}

class _FailingAdminRepository implements AdminRepository {
  @override
  Future<AdminSnapshot> loadAdmin(AdminFilter filter) {
    throw StateError('admin down');
  }
}
