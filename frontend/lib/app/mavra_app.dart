import 'package:flutter/material.dart';

import '../core/auth/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/alerts/data/alerts_api.dart';
import '../features/alerts/domain/alert_models.dart';
import '../features/analytics/data/analytics_api.dart';
import '../features/analytics/domain/analytics_models.dart';
import '../features/auth/data/auth_api.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/events/data/events_api.dart';
import '../features/events/domain/event_models.dart';
import '../features/jobs/data/jobs_api.dart';
import '../features/jobs/domain/job_models.dart';
import '../features/products/data/products_api.dart';
import '../features/products/domain/product_models.dart';
import '../features/today/data/today_api.dart';
import '../features/today/domain/today_models.dart';
import 'router.dart';

class MavraApp extends StatelessWidget {
  const MavraApp({
    super.key,
    this.config = AppConfig.current,
    this.isAuthenticated = false,
    this.authController,
    this.todayRepository,
    this.eventRepository,
    this.alertRepository,
    this.analyticsRepository,
    this.jobsRepository,
    this.productRepository,
    this.initialLocation,
  });

  final AppConfig config;
  final bool isAuthenticated;
  final AuthController? authController;
  final TodayRepository? todayRepository;
  final EventRepository? eventRepository;
  final AlertRepository? alertRepository;
  final AnalyticsRepository? analyticsRepository;
  final JobsRepository? jobsRepository;
  final ProductRepository? productRepository;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    final controller = authController ?? _defaultAuthController();
    final router = createMavraRouter(
      authController: controller,
      todayRepository: todayRepository ?? _defaultTodayRepository(),
      eventRepository: eventRepository ?? _defaultEventRepository(),
      alertRepository: alertRepository ?? _defaultAlertRepository(),
      analyticsRepository: analyticsRepository ?? _defaultAnalyticsRepository(),
      jobsRepository: jobsRepository ?? _defaultJobsRepository(),
      productRepository: productRepository ?? _defaultProductRepository(),
      initialLocation: initialLocation,
    );

    return MaterialApp.router(
      title: 'Mavra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }

  AuthController _defaultAuthController() {
    return AuthController(
      api: GeneratedAuthApiClient(config: config),
      initialSession: isAuthenticated
          ? AuthSession(
              accessToken: 'local-preview-access',
              refreshToken: 'local-preview-refresh',
              expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
              username: 'mavra',
              permissions: const {'schedule:read', 'user:read'},
            )
          : null,
    );
  }

  TodayRepository _defaultTodayRepository() {
    return GeneratedTodayRepository(config: config);
  }

  EventRepository _defaultEventRepository() {
    return GeneratedEventRepository(config: config);
  }

  AlertRepository _defaultAlertRepository() {
    return GeneratedAlertRepository(config: config);
  }

  AnalyticsRepository _defaultAnalyticsRepository() {
    return GeneratedAnalyticsRepository(config: config);
  }

  JobsRepository _defaultJobsRepository() {
    return GeneratedJobsRepository(config: config);
  }

  ProductRepository _defaultProductRepository() {
    return GeneratedProductRepository(config: config);
  }
}
