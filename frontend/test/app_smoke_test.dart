import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/app/mavra_app.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';
import 'package:mavra_frontend/core/notifications/mavra_notifier.dart';

void main() {
  testWidgets('renders the unauthenticated login shell', (tester) async {
    await tester.pumpWidget(
      MavraApp(
        authRepository: AuthRepository(
          storage: InMemoryTokenStorage(),
          policy: TokenPersistencePolicy.nativeSecureStorage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mavra'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Mavra watches quietly'), findsOneWidget);
    expect(MavraNotifier.scaffoldMessengerKey.currentState, isNotNull);
  });

  testWidgets('defaults to light theme even when the platform is dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(
      MavraApp(
        authRepository: AuthRepository(
          storage: InMemoryTokenStorage(),
          policy: TokenPersistencePolicy.nativeSecureStorage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.text('Login'))).brightness,
      Brightness.light,
    );
  });

  testWidgets('skips local restore for web cookie token policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MavraApp(
        authRepository: AuthRepository(
          storage: InMemoryTokenStorage(),
          policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Mavra'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('shows a restore failure screen when session restore fails', (
    tester,
  ) async {
    await tester.pumpWidget(
      MavraApp(
        authRepository: AuthRepository(
          storage: _ThrowingTokenStorage(),
          policy: TokenPersistencePolicy.nativeSecureStorage,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Failed to restore your session.'), findsOneWidget);
  });
}

class _ThrowingTokenStorage implements TokenStorage {
  @override
  Future<void> delete(String key) {
    throw const FormatException('storage failure');
  }

  @override
  Future<String?> read(String key) {
    throw const FormatException('storage failure');
  }

  @override
  Future<void> write(String key, String value) {
    throw const FormatException('storage failure');
  }
}
