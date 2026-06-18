import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/app/mavra_app.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/features/auth/domain/auth_models.dart';
import 'package:mavra_frontend/features/settings/domain/settings_models.dart';
import 'package:mavra_frontend/features/today/domain/today_models.dart';

void main() {
  testWidgets('redirects unauthenticated users from /today to login', (
    tester,
  ) async {
    final auth = AuthController(api: FakeAuthApi());

    await tester.pumpWidget(
      MavraApp(authController: auth, initialLocation: '/today'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mavra'), findsOneWidget);
    expect(find.text('Mavra watches quietly'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
  });

  testWidgets('submits username and password then navigates to /today', (
    tester,
  ) async {
    final api = FakeAuthApi();
    final auth = AuthController(api: api);

    await tester.pumpWidget(
      MavraApp(
        authController: auth,
        todayRepository: const _FakeTodayRepository(),
        initialLocation: '/login',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-username-field')),
      'mavra',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(api.lastLogin?.username, 'mavra');
    expect(api.lastLogin?.password, 'secret-password');
    expect(find.text('Today'), findsWidgets);
  });

  test('persists login sessions through the auth repository', () async {
    final storage = InMemoryTokenStorage();
    final repository = AuthRepository(
      storage: storage,
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    final auth = AuthController(api: FakeAuthApi(), repository: repository);

    await auth.login(
      const LoginCredentials(username: 'mavra', password: 'secret-password'),
    );

    final reloaded = AuthRepository(
      storage: storage,
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );

    expect((await reloaded.loadSession())?.username, 'mavra');
  });

  test('restores saved sessions through the auth repository', () async {
    final repository = AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    await repository.saveSession(
      _session(username: 'restored', permissions: {'schedule:read'}),
    );
    final auth = AuthController(api: FakeAuthApi(), repository: repository);

    await auth.restoreSession();

    expect(auth.session?.username, 'restored');
    expect(auth.isAuthenticated, isTrue);
  });

  testWidgets('default app restores saved sessions before route guarding', (
    tester,
  ) async {
    final repository = AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    await repository.saveSession(
      _session(username: 'restored', permissions: {'config:read'}),
    );

    await tester.pumpWidget(
      MavraApp(
        authRepository: repository,
        settingsRepository: const _FakeSettingsRepository(),
        todayRepository: const _FakeTodayRepository(),
        initialLocation: '/settings',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Theme preference: system'), findsOneWidget);
    expect(find.text('Login'), findsNothing);
  });

  test('logout clears saved repository sessions', () async {
    final repository = AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    final auth = AuthController(api: FakeAuthApi(), repository: repository);
    await auth.login(
      const LoginCredentials(username: 'mavra', password: 'secret-password'),
    );

    await auth.logout();

    expect(auth.session, isNull);
    expect(await repository.loadSession(), isNull);
  });

  testWidgets('shows a permission state for guarded routes', (tester) async {
    final auth = AuthController(
      api: FakeAuthApi(),
      initialSession: _session(
        username: 'viewer',
        permissions: {'schedule:read'},
      ),
    );

    await tester.pumpWidget(
      MavraApp(authController: auth, initialLocation: '/admin/users'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Permission required'), findsOneWidget);
    expect(find.textContaining('user:read'), findsOneWidget);
    expect(find.text('Go to Today'), findsOneWidget);
  });

  testWidgets('renders profile user info, sessions, and login history', (
    tester,
  ) async {
    final auth = AuthController(
      api: FakeAuthApi(),
      initialSession: _session(username: 'mavra', permissions: {'user:read'}),
    );

    await tester.pumpWidget(
      MavraApp(authController: auth, initialLocation: '/profile'),
    );
    await tester.pumpAndSettle();

    expect(find.text('mavra'), findsWidgets);
    expect(find.text('mavra@example.com'), findsOneWidget);
    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Windows desktop'), findsOneWidget);
    expect(find.text('Login history'), findsOneWidget);
    expect(find.text('127.0.0.1'), findsOneWidget);
  });
}

class FakeAuthApi implements AuthApiClient {
  LoginCredentials? lastLogin;

  @override
  Future<AuthSession> login(LoginCredentials credentials) async {
    lastLogin = credentials;
    return _session(
      username: credentials.username,
      permissions: {'schedule:read', 'user:read'},
    );
  }

  @override
  Future<void> register(RegisterAccountInput input) async {}

  @override
  Future<AccountProfile> fetchProfile() async {
    return const AccountProfile(
      username: 'mavra',
      email: 'mavra@example.com',
      role: 'admin',
      permissions: {'user:read'},
    );
  }

  @override
  Future<List<AccountSession>> listSessions() async {
    return [
      AccountSession(
        id: 1,
        device: 'Windows desktop',
        ipAddress: '127.0.0.1',
        createdAt: DateTime.utc(2026, 6, 16),
        lastActiveAt: DateTime.utc(2026, 6, 16, 8),
      ),
    ];
  }

  @override
  Future<List<LoginHistoryEntry>> listLoginHistory() async {
    return [
      LoginHistoryEntry(
        id: 1,
        ipAddress: '127.0.0.1',
        userAgent: 'Flutter test',
        createdAt: DateTime.utc(2026, 6, 16),
      ),
    ];
  }

  @override
  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async {
    return WeChatExchangeResult.bound(
      _session(username: 'wechat-user', permissions: {'schedule:read'}),
    );
  }

  @override
  Future<void> logout() async {}
}

class _FakeTodayRepository implements TodayRepository {
  const _FakeTodayRepository();

  @override
  Future<TodaySnapshot> loadToday() async => TodaySnapshot.quiet();
}

class _FakeSettingsRepository implements SettingsRepository {
  const _FakeSettingsRepository();

  @override
  Future<SettingsSnapshot> loadSettings() async =>
      const SettingsSnapshot.empty();

  @override
  Future<SettingsSnapshot> saveSettings(SettingsDraft draft) async {
    return SettingsSnapshot.empty();
  }
}

AuthSession _session({
  required String username,
  required Set<String> permissions,
}) {
  return AuthSession(
    accessToken: 'access-$username',
    refreshToken: 'refresh-$username',
    expiresAt: DateTime.utc(2026, 6, 16, 9),
    username: username,
    permissions: permissions,
  );
}
