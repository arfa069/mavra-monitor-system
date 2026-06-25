import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/core/widgets/mavra_style_helpers.dart';

void main() {
  testWidgets('filter buttons render as stable pill controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: MavraFilterButton.filled(
            icon: Icons.add,
            label: 'Add Product',
            onPressed: null,
          ),
        ),
      ),
    );

    final container = tester.widget<Container>(find.byType(Container));
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.borderRadius, BorderRadius.circular(999));
  });

  testWidgets('filter input follows the focused blue hairline contract', (
    tester,
  ) async {
    late InputDecoration decoration;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) {
            decoration = MavraInputStyle.filterInput(
              context: context,
              label: 'Search',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final focused = decoration.focusedBorder! as OutlineInputBorder;
    final enabled = decoration.enabledBorder! as OutlineInputBorder;

    expect(enabled.borderRadius, BorderRadius.circular(8));
    expect(focused.borderSide.color, const Color(0xFF1D4ED8));
    expect(focused.borderSide.width, 2);
  });
}
