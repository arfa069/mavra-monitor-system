import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
