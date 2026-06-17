import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mavra_frontend/app/mavra_app.dart';
import 'package:mavra_frontend/core/auth/auth_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the login shell', (tester) async {
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
}
