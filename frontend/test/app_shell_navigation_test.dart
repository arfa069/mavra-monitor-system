import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mavra_frontend/app/app_shell.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/features/auth/domain/auth_models.dart';
import 'package:mavra_frontend/visual_qa/visual_qa_app.dart';

void main() {
  testWidgets('authenticated shell exposes the React primary navigation', (
    tester,
  ) async {
    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/today'));
    await tester.pumpAndSettle();

    const routes = [
      '/today',
      '/dashboard',
      '/events',
      '/jobs',
      '/products',
      '/schedule',
      '/smart-home',
      '/admin/blog',
      '/admin/users',
      '/admin/audit-logs',
    ];

    for (final route in routes) {
      expect(
        find.byKey(Key('app-shell-nav-$route')),
        findsOneWidget,
        reason: '$route should be visible in the authenticated app shell',
      );
    }
  });

  testWidgets('analytics alias lands on the dashboard shell destination', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildShellHarness(
        initialLocation: '/analytics',
        permissions: const {'config:read'},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard page'), findsOneWidget);
    expect(find.byKey(const Key('app-shell-nav-/analytics')), findsNothing);

    final dashboardTile = tester.widget<ListTile>(
      find.descendant(
        of: find.byKey(const Key('app-shell-nav-/dashboard')),
        matching: find.byType(ListTile),
      ),
    );
    expect(dashboardTile.selected, isTrue);
  });

  testWidgets('limited users do not see gated admin or blog navigation', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _buildShellHarness(
        initialLocation: '/today',
        permissions: const {'config:read'},
      ),
    );
    await tester.pumpAndSettle();

    for (final route in const [
      '/today',
      '/dashboard',
      '/events',
      '/jobs',
      '/products',
      '/schedule',
      '/smart-home',
    ]) {
      expect(find.byKey(Key('app-shell-nav-$route')), findsOneWidget);
    }

    expect(find.byKey(const Key('app-shell-nav-/admin/blog')), findsNothing);
    expect(find.byKey(const Key('app-shell-nav-/admin/users')), findsNothing);
    expect(
      find.byKey(const Key('app-shell-nav-/admin/audit-logs')),
      findsNothing,
    );
  });
}

Widget _buildShellHarness({
  required String initialLocation,
  required Set<String> permissions,
}) {
  final authController = AuthController(
    api: const _ShellHarnessAuthApi(),
    initialSession: AuthSession(
      accessToken: 'shell-access',
      refreshToken: 'shell-refresh',
      expiresAt: DateTime.utc(2026, 6, 18, 12),
      username: 'shell-user',
      permissions: permissions,
    ),
  );

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/analytics', redirect: (context, state) => '/dashboard'),
      ShellRoute(
        builder: (context, state, child) =>
            MavraShell(authController: authController, child: child),
        routes: [
          for (final route in const [
            '/today',
            '/dashboard',
            '/events',
            '/jobs',
            '/products',
            '/schedule',
            '/smart-home',
            '/admin/blog',
            '/admin/users',
            '/admin/audit-logs',
          ])
            GoRoute(
              path: route,
              builder: (context, state) =>
                  Center(child: Text('${_routeTitle(route)} page')),
            ),
        ],
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

String _routeTitle(String route) {
  return switch (route) {
    '/dashboard' => 'Dashboard',
    '/admin/blog' => 'Blog',
    '/admin/users' => 'Users',
    '/admin/audit-logs' => 'Audit logs',
    _ => route.substring(1),
  };
}

class _ShellHarnessAuthApi implements AuthApiClient {
  const _ShellHarnessAuthApi();

  @override
  Future<AuthSession> login(LoginCredentials credentials) async {
    throw UnimplementedError();
  }

  @override
  Future<void> register(RegisterAccountInput input) async {}

  @override
  Future<AccountProfile> fetchProfile() async {
    throw UnimplementedError();
  }

  @override
  Future<List<AccountSession>> listSessions() async => const [];

  @override
  Future<List<LoginHistoryEntry>> listLoginHistory() async => const [];

  @override
  Future<AccountProfile> updateProfile(AccountProfileDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<AuthSession> changePassword(PasswordChangeDraft draft) async {
    throw UnimplementedError();
  }

  @override
  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}
}
