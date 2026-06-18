import 'package:flutter/material.dart';

class MavraSideSheet {
  const MavraSideSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    required String title,
    double wideBreakpoint = 760,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < wideBreakpoint) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        builder: (context) => _MavraSheetFrame(
          key: const Key('mavra-side-sheet-mobile'),
          title: title,
          child: child,
        ),
      );
    }

    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SizedBox(
                width: width * 0.42,
                height: double.infinity,
                child: _MavraSheetFrame(
                  key: const Key('mavra-side-sheet-panel'),
                  title: title,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MavraSheetFrame extends StatelessWidget {
  const _MavraSheetFrame({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(child: child),
            ),
          ],
        ),
      ),
    );
  }
}
