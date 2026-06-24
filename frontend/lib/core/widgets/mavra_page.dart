import 'package:flutter/material.dart';

class MavraPageScaffold extends StatelessWidget {
  const MavraPageScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.status,
    this.isLoading = false,
    this.error,
    this.empty,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? status;
  final bool isLoading;
  final String? error;
  final Widget? empty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = <Widget>[
      if (isLoading)
        const LinearProgressIndicator(key: Key('mavra-page-loading')),
      if (error != null)
        _MavraStatusBanner(
          key: const Key('mavra-page-error'),
          message: error!,
          icon: Icons.error_outline,
          color: Theme.of(context).colorScheme.errorContainer,
        ),
      if (empty != null)
        KeyedSubtree(
          key: const Key('mavra-page-empty'),
          child: empty!,
        ),
      if (!isLoading && error == null && empty == null) child,
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: actions,
                  ),
                ],
              ],
            ),
            if (status != null) ...[
              const SizedBox(height: 12),
              status!,
            ],
            const SizedBox(height: 16),
            ...content,
          ],
        ),
      ),
    );
  }
}

class _MavraStatusBanner extends StatelessWidget {
  const _MavraStatusBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
