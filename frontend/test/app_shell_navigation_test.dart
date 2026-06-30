import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mavra_frontend/app/app_shell.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
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

    expect(find.text('Event'), findsOneWidget);
    expect(find.text('Products'), findsOneWidget);
    expect(find.text('Activity'), findsNothing);
    expect(find.text('Prices'), findsNothing);
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

  testWidgets('desktop shell uses a MiniMax-style dark brand rail', (
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

    final rail = tester.widget<Material>(
      find.byKey(const Key('app-shell-brand-rail')),
    );
    expect(rail.color, AppTheme.primary);
  });

  testWidgets('user menu toggles between light and dark themes', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/today'));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Mavra Monitor System'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byKey(const Key('app-shell-user-menu')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('app-shell-theme-toggle')), findsOneWidget);
    expect(find.text('Switch to Dark theme'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-shell-theme-toggle')));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Mavra Monitor System'))).brightness,
      Brightness.dark,
    );

    await tester.tap(find.byKey(const Key('app-shell-user-menu')));
    await tester.pumpAndSettle();
    expect(find.text('Switch to Light theme'), findsOneWidget);

    await tester.tap(find.byKey(const Key('app-shell-theme-toggle')));
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Mavra Monitor System'))).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'theme changes keep the active route instead of replaying initialLocation',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildVisualQaApp(initialLocation: '/today'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('app-shell-nav-/events')));
      await tester.pumpAndSettle();
      expect(find.text('System Events'), findsOneWidget);

      await tester.tap(find.byKey(const Key('app-shell-user-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-shell-theme-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('System Events'), findsOneWidget);
    },
  );

  testWidgets('dashboard route renders the restored analytics page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsWidgets);
    expect(
      find.text('Monitor system status, price trends, and candidate matching'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dashboard-range-toolbar')), findsOneWidget);
    expect(find.byKey(const Key('app-shell-nav-/analytics')), findsNothing);
  });

  testWidgets('events route renders the restored event center page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/events'));
    await tester.pumpAndSettle();

    expect(find.text('System Events'), findsOneWidget);
    expect(find.text('Event Center'), findsOneWidget);
    expect(find.byKey(const Key('events-filter-toolbar')), findsOneWidget);
    expect(find.text('visual-qa-admin logged in'), findsOneWidget);
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

  testWidgets('audit logs route renders the standalone audit page', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildVisualQaApp(initialLocation: '/admin/audit-logs'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audit Logs'), findsWidgets);
    expect(find.text('View system operation audit records'), findsOneWidget);
    expect(find.text('User Management'), findsNothing);
    expect(find.byKey(const Key('admin-create-user-button')), findsNothing);
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
