import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mavra_frontend/app/mavra_app.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/features/auth/domain/auth_models.dart';
import 'package:mavra_frontend/features/today/domain/today_models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('logs in through the Flutter auth flow', (tester) async {
    final auth = AuthController(api: SmokeAuthApi());

    await tester.pumpWidget(
      MavraApp(
        authController: auth,
        todayRepository: SmokeTodayRepository(),
        initialLocation: '/login',
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-username-field')),
      'smoke',
    );
    await tester.enterText(
      find.byKey(const Key('login-password-field')),
      'secret-password',
    );
    await tester.tap(find.byKey(const Key('login-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
  });
}

class SmokeTodayRepository implements TodayRepository {
  @override
  Future<TodaySnapshot> loadToday() async => TodaySnapshot.quiet();
}

class SmokeAuthApi implements AuthApiClient {
  @override
  Future<AuthSession> login(LoginCredentials credentials) async {
    return AuthSession(
      accessToken: 'smoke-access',
      refreshToken: 'smoke-refresh',
      expiresAt: DateTime.utc(2026, 6, 16, 9),
      username: credentials.username,
      permissions: {'schedule:read', 'user:read'},
    );
  }

  @override
  Future<void> register(RegisterAccountInput input) async {}

  @override
  Future<AccountProfile> fetchProfile() async {
    return const AccountProfile(
      username: 'smoke',
      email: 'smoke@example.com',
      role: 'user',
      permissions: {'schedule:read', 'user:read'},
    );
  }

  @override
  Future<List<AccountSession>> listSessions() async => const [];

  @override
  Future<List<LoginHistoryEntry>> listLoginHistory() async => const [];

  @override
  Future<WeChatExchangeResult> exchangeWeChatCode(String code) async {
    return WeChatExchangeResult.bound(
      AuthSession(
        accessToken: 'wechat-access',
        refreshToken: 'wechat-refresh',
        expiresAt: DateTime.utc(2026, 6, 16, 9),
        username: 'wechat-smoke',
        permissions: {'schedule:read'},
      ),
    );
  }

  @override
  Future<void> logout() async {}
}
