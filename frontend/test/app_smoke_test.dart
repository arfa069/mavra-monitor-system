import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/app/mavra_app.dart';

void main() {
  testWidgets('renders the unauthenticated login shell', (tester) async {
    await tester.pumpWidget(const MavraApp());

    expect(find.text('Mavra'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Mavra watches quietly'), findsOneWidget);
  });
}
