import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'url_strategy.dart';

Future<void> bootstrap(Widget app, {String? apiBaseUrl}) async {
  final resolvedApiBaseUrl =
      apiBaseUrl ??
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:8000/api/v1',
      );
  configureUrlStrategy();
  await SentryFlutter.init((options) {
    final dsn = const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
    options.dsn = dsn;
    options.environment = const String.fromEnvironment(
      'SENTRY_ENVIRONMENT',
      defaultValue: 'development',
    );
    options.debug = !const bool.fromEnvironment('dart.vm.product');
    options.tracesSampleRate = const bool.fromEnvironment('dart.vm.product')
        ? 0.1
        : 1.0;
    options.captureFailedRequests = true;
    options.enableAutoPerformanceTracing = true;
    options.enableFramesTracking = true;
    final apiHost = Uri.tryParse(resolvedApiBaseUrl)?.host;
    if (apiHost != null && apiHost.isNotEmpty) {
      options.tracePropagationTargets
        ..clear()
        ..addAll(<String>[apiHost, 'localhost', '127.0.0.1', '::1']);
    }
  }, appRunner: () => bootstrapWidget(SentryWidget(child: app)));
}

void bootstrapWidget(Widget app) {
  runApp(app);
}
