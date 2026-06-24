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

  test(
    'expired saved native session refresh failure clears authentication',
    () async {
      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.nativeSecureStorage,
        refreshRemote: () async => null,
      );
      await repository.saveSession(
        _session(
          username: 'expired',
          permissions: {'schedule:read'},
          expiresAt: DateTime.now().toUtc().subtract(
            const Duration(minutes: 1),
          ),
        ),
      );
      final auth = AuthController(api: FakeAuthApi(), repository: repository);

      await auth.restoreSession();

      expect(auth.session, isNull);
      expect(auth.isAuthenticated, isFalse);
      expect(await repository.loadSession(), isNull);
    },
  );

  test('auth controller follows repository session invalidation', () async {
    final repository = AuthRepository(
      storage: InMemoryTokenStorage(),
      policy: TokenPersistencePolicy.nativeSecureStorage,
    );
    await repository.saveSession(
      _session(username: 'restored', permissions: {'schedule:read'}),
    );
    final auth = AuthController(api: FakeAuthApi(), repository: repository);
    await auth.restoreSession();

    await repository.clearLocalSession();

    expect(auth.session, isNull);
    expect(auth.isAuthenticated, isFalse);
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

  testWidgets(
    'default web app restores cookie-backed sessions before guarding',
    (tester) async {
      var refreshCalls = 0;
      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
        refreshRemote: () async {
          refreshCalls += 1;
          return _session(
            username: 'cookie-restored',
            permissions: {'config:read'},
          );
        },
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

      expect(refreshCalls, 1);
      expect(repository.currentSession?.username, 'cookie-restored');
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Theme preference: system'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    },
  );

  testWidgets(
    'default web app preserves the browser route after cookie restore',
    (tester) async {
      final binding = TestWidgetsFlutterBinding.ensureInitialized();
      binding.platformDispatcher.defaultRouteNameTestValue = '/settings';
      addTearDown(binding.platformDispatcher.clearDefaultRouteNameTestValue);

      final repository = AuthRepository(
        storage: InMemoryTokenStorage(),
        policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
        refreshRemote: () async =>
            _session(username: 'cookie-restored', permissions: {'config:read'}),
      );

      await tester.pumpWidget(
        MavraApp(
          authRepository: repository,
          settingsRepository: const _FakeSettingsRepository(),
          todayRepository: const _FakeTodayRepository(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Theme preference: system'), findsOneWidget);
      expect(find.text('Login'), findsNothing);
    },
  );

  testWidgets('authenticated login redirect preserves hash route targets', (
    tester,
  ) async {
    final auth = AuthController(
      api: FakeAuthApi(),
      initialSession: _session(
        username: 'cookie-restored',
        permissions: {'config:read'},
      ),
    );

    await tester.pumpWidget(
      MavraApp(
        authController: auth,
        settingsRepository: const _FakeSettingsRepository(),
        todayRepository: const _FakeTodayRepository(),
        initialLocation: '/login#/settings',
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

  testWidgets('allows personal settings without config read permission', (
    tester,
  ) async {
    final auth = AuthController(
      api: FakeAuthApi(),
      initialSession: _session(username: 'viewer', permissions: {'user:read'}),
    );

    await tester.pumpWidget(
      MavraApp(
        authController: auth,
        settingsRepository: const _FakeSettingsRepository(),
        initialLocation: '/settings',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Page transition speed'), findsOneWidget);
    expect(find.text('Permission required'), findsNothing);
    expect(find.text('API Environment'), findsOneWidget);
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
    expect(find.text('mavra@example.com'), findsWidgets);

    await tester.drag(
      find.byKey(const Key('profile-page-list')),
      const Offset(0, -760),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sessions'), findsOneWidget);
    expect(find.text('Windows desktop'), findsOneWidget);
    expect(find.text('Login history'), findsOneWidget);
    expect(find.text('127.0.0.1'), findsOneWidget);
  });

  testWidgets('updates profile details and changes password', (tester) async {
    final api = FakeAuthApi();
    final auth = AuthController(
      api: api,
      initialSession: _session(username: 'mavra', permissions: {'user:read'}),
    );

    await tester.pumpWidget(
      MavraApp(authController: auth, initialLocation: '/profile'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit personal info'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('profile-username-field')),
      'updated-mavra',
    );
    await tester.enterText(
      find.byKey(const Key('profile-email-field')),
      'updated@example.com',
    );
    await tester.tap(find.byKey(const Key('profile-save-button')));
    await tester.pumpAndSettle();

    expect(api.lastProfileDraft?.username, 'updated-mavra');
    expect(api.lastProfileDraft?.email, 'updated@example.com');
    expect(find.text('Profile updated successfully'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('profile-page-list')),
      const Offset(0, -480),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('profile-current-password-field')),
      'old-password',
    );
    await tester.enterText(
      find.byKey(const Key('profile-new-password-field')),
      'NewPassword123!',
    );
    await tester.tap(find.byKey(const Key('profile-change-password-button')));
    await tester.pumpAndSettle();

    expect(api.lastPasswordDraft?.currentPassword, 'old-password');
    expect(api.lastPasswordDraft?.newPassword, 'NewPassword123!');
    expect(find.text('Password changed successfully'), findsOneWidget);
  });

  testWidgets('does not render the WeChat temporary token in the callback UI', (
    tester,
  ) async {
    final auth = AuthController(api: _UnboundWeChatAuthApi());

    await tester.pumpWidget(
      MavraApp(
        authController: auth,
        initialLocation: '/auth/wechat/callback?code=wechat-demo',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('WeChat account is unbound'), findsOneWidget);
    expect(find.textContaining('temp-secret-token'), findsNothing);
    expect(find.textContaining('link your account'), findsOneWidget);
  });
}

class FakeAuthApi implements AuthApiClient {
  LoginCredentials? lastLogin;
  AccountProfileDraft? lastProfileDraft;
  PasswordChangeDraft? lastPasswordDraft;

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
  Future<AccountProfile> updateProfile(AccountProfileDraft draft) async {
    lastProfileDraft = draft;
    return AccountProfile(
      username: draft.username,
      email: draft.email,
      role: 'admin',
      permissions: const {'user:read'},
    );
  }

  @override
  Future<AuthSession> changePassword(PasswordChangeDraft draft) async {
    lastPasswordDraft = draft;
    return _session(username: 'mavra', permissions: {'user:read'});
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

  @override
  Future<SettingsSnapshot> saveMotionSpeed(String motionSpeed) async {
    return SettingsSnapshot(
      userConfig: null,
      themeMode: 'system',
      motionSpeed: motionSpeed,
    );
  }
}

class _UnboundWeChatAuthApi extends FakeAuthApi {
  @override
  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async {
    return WeChatExchangeResult.unbound(
      tempToken: 'temp-secret-token',
      nextPath: '/register',
    );
  }
}

AuthSession _session({
  required String username,
  required Set<String> permissions,
  DateTime? expiresAt,
}) {
  return AuthSession(
    accessToken: 'access-$username',
    refreshToken: 'refresh-$username',
    expiresAt:
        expiresAt ?? DateTime.now().toUtc().add(const Duration(hours: 1)),
    username: username,
    permissions: permissions,
  );
}
