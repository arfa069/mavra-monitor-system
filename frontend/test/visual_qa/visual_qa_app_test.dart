import 'dart:ui';

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

  testWidgets('visual QA harness renders dashboard fixture', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Analytics'), findsWidgets);
    expect(find.text('Monitored Products'), findsWidgets);
    expect(find.text('System Operations'), findsWidgets);
  });

  testWidgets('visual QA harness renders events fixture', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/events'));
    await tester.pumpAndSettle();

    expect(find.text('Event Center'), findsOneWidget);
    expect(find.text('visual-qa-admin logged in'), findsOneWidget);
    expect(find.text('Boss profile requires review'), findsOneWidget);
    expect(
      find.text('Crawler worker restarted after transient failure'),
      findsOneWidget,
    );
  });
}
