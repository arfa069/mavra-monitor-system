import 'package:flutter/material.dart';
import 'package:mavra_api/mavra_api.dart' as generated;

import '../core/api/authenticated_mavra_api.dart';
import '../core/auth/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/platform/platform_capabilities.dart';
import '../core/theme/app_theme.dart';
import '../features/alerts/data/alerts_api.dart';
import '../features/alerts/domain/alert_models.dart';
import '../features/admin/data/admin_api.dart';
import '../features/admin/domain/admin_models.dart';
import '../features/analytics/data/analytics_api.dart';
import '../features/analytics/domain/analytics_models.dart';
import '../features/auth/data/auth_api.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/blog/data/blog_api.dart';
import '../features/blog/domain/blog_models.dart';
import '../features/events/data/events_api.dart';
import '../features/events/domain/event_models.dart';
import '../features/jobs/data/jobs_api.dart';
import '../features/jobs/domain/job_models.dart';
import '../features/products/data/products_api.dart';
import '../features/products/domain/product_models.dart';
import '../features/schedule/data/schedule_api.dart';
import '../features/schedule/domain/schedule_models.dart';
import '../features/settings/data/settings_api.dart';
import '../features/settings/domain/settings_models.dart';
import '../features/smart_home/data/smart_home_api.dart';
import '../features/smart_home/domain/smart_home_models.dart';
import '../features/today/data/today_api.dart';
import '../features/today/domain/today_models.dart';
import 'router.dart';

class MavraApp extends StatefulWidget {
  const MavraApp({
    super.key,
    this.config = AppConfig.current,
    this.isAuthenticated = false,
    this.authController,
    this.authRepository,
    this.todayRepository,
    this.eventRepository,
    this.alertRepository,
    this.adminRepository,
    this.analyticsRepository,
    this.blogRepository,
    this.jobsRepository,
    this.productRepository,
    this.scheduleRepository,
    this.settingsRepository,
    this.smartHomeRepository,
    this.initialLocation,
  });

  final AppConfig config;
  final bool isAuthenticated;
  final AuthController? authController;
  final AuthRepository? authRepository;
  final TodayRepository? todayRepository;
  final EventRepository? eventRepository;
  final AlertRepository? alertRepository;
  final AdminRepository? adminRepository;
  final AnalyticsRepository? analyticsRepository;
  final BlogRepository? blogRepository;
  final JobsRepository? jobsRepository;
  final ProductRepository? productRepository;
  final ScheduleRepository? scheduleRepository;
  final SettingsRepository? settingsRepository;
  final SmartHomeRepository? smartHomeRepository;
  final String? initialLocation;

  @override
  State<MavraApp> createState() => _MavraAppState();
}

class _MavraAppState extends State<MavraApp> {
  AuthController? _ownedAuthController;
  AuthRepository? _ownedAuthRepository;
  generated.MavraApi? _ownedApiClient;
  Future<void>? _defaultRestoreFuture;

  @override
  void initState() {
    super.initState();
    _defaultRestoreFuture = _restoreDefaultSession();
  }

  @override
  void didUpdateWidget(covariant MavraApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController ||
        oldWidget.authRepository != widget.authRepository ||
        oldWidget.config != widget.config ||
        oldWidget.isAuthenticated != widget.isAuthenticated) {
      _disposeOwnedAuthController();
      _defaultRestoreFuture = _restoreDefaultSession();
    }
  }

  @override
  void dispose() {
    _disposeOwnedAuthController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restoreFuture = _defaultRestoreFuture;
    if (restoreFuture != null) {
      return FutureBuilder<void>(
        future: restoreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return _buildRestoringApp();
          }
          return _buildRouterApp();
        },
      );
    }

    return _buildRouterApp();
  }

  Widget _buildRouterApp() {
    final controller = _authController();
    final router = createMavraRouter(
      authController: controller,
      config: widget.config,
      todayRepository: widget.todayRepository ?? _defaultTodayRepository(),
      eventRepository: widget.eventRepository ?? _defaultEventRepository(),
      alertRepository: widget.alertRepository ?? _defaultAlertRepository(),
      adminRepository: widget.adminRepository ?? _defaultAdminRepository(),
      analyticsRepository:
          widget.analyticsRepository ?? _defaultAnalyticsRepository(),
      blogRepository: widget.blogRepository ?? _defaultBlogRepository(),
      jobsRepository: widget.jobsRepository ?? _defaultJobsRepository(),
      productRepository:
          widget.productRepository ?? _defaultProductRepository(),
      scheduleRepository:
          widget.scheduleRepository ?? _defaultScheduleRepository(),
      settingsRepository:
          widget.settingsRepository ?? _defaultSettingsRepository(),
      smartHomeRepository:
          widget.smartHomeRepository ?? _defaultSmartHomeRepository(),
      initialLocation: widget.initialLocation,
    );

    return MaterialApp.router(
      title: 'Mavra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }

  Widget _buildRestoringApp() {
    return MaterialApp(
      title: 'Mavra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  AuthController _authController() {
    return widget.authController ??
        (_ownedAuthController ??= _defaultAuthController());
  }

  Future<void>? _restoreDefaultSession() {
    if (widget.authController != null) {
      return null;
    }
    final repository = _defaultAuthRepository();
    if (repository.policy == TokenPersistencePolicy.webHttpOnlyRefreshCookie) {
      return null;
    }
    return _authController().restoreSession();
  }

  void _disposeOwnedAuthController() {
    _ownedAuthController?.dispose();
    _ownedAuthController = null;
    _ownedAuthRepository = null;
    _ownedApiClient = null;
  }

  AuthController _defaultAuthController() {
    final repository = _defaultAuthRepository();
    return AuthController(
      api: GeneratedAuthApiClient(
        config: widget.config,
        client: _defaultGeneratedApiClient(),
      ),
      repository: repository,
      initialSession: widget.isAuthenticated
          ? AuthSession(
              accessToken: 'local-preview-access',
              refreshToken: 'local-preview-refresh',
              expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
              username: 'mavra',
              permissions: const {
                'schedule:read',
                'smart_home:read',
                'smart_home:control',
                'user:read',
                'user:manage',
                'rbac:read',
                'rbac:manage',
                'blog:read_admin',
                'blog:write',
                'config:read',
                'config:write',
              },
            )
          : null,
    );
  }

  AuthRepository _defaultAuthRepository() {
    final injected = widget.authRepository;
    if (injected != null) {
      return injected;
    }
    final existing = _ownedAuthRepository;
    if (existing != null) {
      return existing;
    }

    final capabilities = PlatformCapabilities.current();
    late final AuthRepository repository;
    repository =
        capabilities.secureStorageMode == SecureStorageMode.webCookie
        ? AuthRepository(
            storage: InMemoryTokenStorage(),
            policy: TokenPersistencePolicy.webHttpOnlyRefreshCookie,
            refreshRemote: () => _refreshDefaultSession(repository),
          )
        : AuthRepository(
            storage: const SecureTokenStorage(),
            policy: TokenPersistencePolicy.nativeSecureStorage,
            refreshRemote: () => _refreshDefaultSession(repository),
          );
    _ownedAuthRepository = repository;
    return repository;
  }

  generated.MavraApi _defaultGeneratedApiClient() {
    final existing = _ownedApiClient;
    if (existing != null) {
      return existing;
    }
    final client = createAuthenticatedMavraApi(
      config: widget.config,
      authRepository: _defaultAuthRepository(),
    );
    _ownedApiClient = client;
    return client;
  }

  Future<AuthSession?> _refreshDefaultSession(AuthRepository repository) {
    return refreshGeneratedAuthSession(
      client: _defaultGeneratedApiClient(),
      repository: repository,
    );
  }

  TodayRepository _defaultTodayRepository() {
    return GeneratedTodayRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  EventRepository _defaultEventRepository() {
    return GeneratedEventRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  AlertRepository _defaultAlertRepository() {
    return GeneratedAlertRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  AdminRepository _defaultAdminRepository() {
    return GeneratedAdminRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  AnalyticsRepository _defaultAnalyticsRepository() {
    return GeneratedAnalyticsRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  BlogRepository _defaultBlogRepository() {
    return GeneratedBlogRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  JobsRepository _defaultJobsRepository() {
    return GeneratedJobsRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  ProductRepository _defaultProductRepository() {
    return GeneratedProductRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  ScheduleRepository _defaultScheduleRepository() {
    return GeneratedScheduleRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  SettingsRepository _defaultSettingsRepository() {
    return GeneratedSettingsRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }

  SmartHomeRepository _defaultSmartHomeRepository() {
    return GeneratedSmartHomeRepository(
      config: widget.config,
      client: _defaultGeneratedApiClient(),
    );
  }
}
