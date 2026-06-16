import 'package:flutter/material.dart';

import '../errors/api_error.dart';

class ApiErrorPanel extends StatelessWidget {
  const ApiErrorPanel({
    super.key,
    required this.error,
    this.likelyCause,
    this.nextAction,
    this.onRetry,
  });

  final ApiError error;
  final String? likelyCause;
  final String? nextAction;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'API error',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.message, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Code: ${error.code}'),
            if (likelyCause != null) ...[
              const SizedBox(height: 8),
              Text(likelyCause!),
            ],
            if (nextAction != null) ...[
              const SizedBox(height: 8),
              Text(nextAction!),
            ],
            if (error.traceId != null) ...[
              const SizedBox(height: 8),
              SelectableText('Trace ID: ${error.traceId}'),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.empty,
  });

  final bool isLoading;
  final ApiError? error;
  final Widget? empty;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final currentError = error;
    if (currentError != null) {
      return ApiErrorPanel(error: currentError);
    }
    return empty ?? child;
  }
}
