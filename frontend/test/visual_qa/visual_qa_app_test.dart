import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/visual_qa/visual_qa_app.dart';

void main() {
  testWidgets('visual QA harness renders authenticated protected routes', (
    tester,
  ) async {
    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('visual-qa-admin'), findsOneWidget);
    expect(find.text('Theme preference: system'), findsOneWidget);
  });
}
