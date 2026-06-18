import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/app/mavra_app.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';

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
}
