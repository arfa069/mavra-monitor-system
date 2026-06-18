import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/domain/alert_models.dart';
import '../features/alerts/presentation/alerts_page.dart';
import '../features/admin/domain/admin_models.dart';
import '../features/admin/presentation/admin_page.dart';
import '../features/analytics/domain/analytics_models.dart';
import '../features/analytics/presentation/analytics_page.dart';
import '../features/auth/domain/auth_models.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/profile_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/auth/presentation/wechat_callback_page.dart';
import '../features/blog/domain/blog_models.dart';
import '../features/blog/presentation/blog_page.dart';
import '../core/config/app_config.dart';
import '../features/events/domain/event_models.dart';
import '../features/events/presentation/events_page.dart';
import '../features/jobs/domain/job_models.dart';
import '../features/jobs/presentation/jobs_page.dart';
import '../features/products/domain/product_models.dart';
import '../features/products/presentation/products_page.dart';
import '../features/schedule/domain/schedule_models.dart';
import '../features/schedule/presentation/schedule_page.dart';
import '../features/settings/domain/settings_models.dart';
import '../features/settings/presentation/settings_page.dart';
import '../features/smart_home/domain/smart_home_models.dart';
import '../features/smart_home/presentation/smart_home_page.dart';
import '../features/today/domain/today_models.dart';
import '../features/today/presentation/today_page.dart';
import 'app_shell.dart';

GoRouter createMavraRouter({
  required AuthController authController,
  AppConfig config = AppConfig.current,
  required TodayRepository todayRepository,
  required EventRepository eventRepository,
  required AlertRepository alertRepository,
  required AdminRepository adminRepository,
  required AnalyticsRepository analyticsRepository,
  required BlogRepository blogRepository,
  required JobsRepository jobsRepository,
  required ProductRepository productRepository,
  required ScheduleRepository scheduleRepository,
  required SettingsRepository settingsRepository,
  required SmartHomeRepository smartHomeRepository,
  String? initialLocation,
}) {
  return GoRouter(
    initialLocation:
        initialLocation ??
        (authController.isAuthenticated ? '/today' : '/login'),
    refreshListenable: authController,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final publicRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/auth/wechat/callback';

      if (!authController.isAuthenticated && !publicRoute) {
        return '/login';
      }
      if (authController.isAuthenticated &&
          (location == '/login' || location == '/register')) {
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/today'),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(authController: authController),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegisterPage(authController: authController),
      ),
      GoRoute(
        path: '/auth/wechat/callback',
        builder: (context, state) => WeChatCallbackPage(
          authController: authController,
          queryParameters: state.uri.queryParameters,
        ),
      ),
      GoRoute(path: '/analytics', redirect: (context, state) => '/dashboard'),
      ShellRoute(
        builder: (context, state, child) =>
            MavraShell(authController: authController, child: child),
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, state) =>
                TodayPage(repository: todayRepository),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) =>
                AnalyticsPage(repository: analyticsRepository),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) =>
                EventsPage(repository: eventRepository),
          ),
          GoRoute(
            path: '/alerts',
            builder: (context, state) =>
                AlertsPage(repository: alertRepository),
          ),
          GoRoute(
            path: '/jobs',
            builder: (context, state) => JobsPage(
              repository: jobsRepository,
              permissions: _jobsPermissions(authController),
            ),
          ),
          GoRoute(
            path: '/products',
            builder: (context, state) => ProductsPage(
              repository: productRepository,
              permissions: _productsPermissions(authController),
            ),
          ),
          GoRoute(
            path: '/schedule',
            builder: (context, state) => SchedulePage(
              repository: scheduleRepository,
              permissions: _schedulePermissions(authController),
            ),
          ),
          GoRoute(
            path: '/smart-home',
            builder: (context, state) => SmartHomePage(
              repository: smartHomeRepository,
              permissions: _smartHomePermissions(authController),
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) =>
                ProfilePage(authController: authController),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => SettingsPage(
              repository: settingsRepository,
              config: config,
              permissions: _settingsPermissions(authController),
            ),
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => _permissionPage(
              authController,
              'user:read',
              AdminPage(
                repository: adminRepository,
                permissions: _adminPermissions(authController),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/audit-logs',
            builder: (context, state) => _permissionPage(
              authController,
              'user:read',
              AdminPage(
                repository: adminRepository,
                permissions: _adminPermissions(authController),
              ),
            ),
          ),
          GoRoute(
            path: '/admin/blog',
            builder: (context, state) => _permissionPage(
              authController,
              'blog:read_admin',
              BlogPage(
                repository: blogRepository,
                permissions: _blogPermissions(authController),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

Set<String> _adminPermissions(AuthController authController) {
  return _permissions(authController, const {
    'user:read',
    'user:manage',
    'rbac:read',
    'rbac:manage',
  });
}

Set<String> _blogPermissions(AuthController authController) {
  return _permissions(authController, const {'blog:read_admin', 'blog:write'});
}

Set<String> _settingsPermissions(AuthController authController) {
  return _permissions(authController, const {'config:read', 'config:write'});
}

Set<String> _jobsPermissions(AuthController authController) {
  return _permissions(authController, const {
    'crawl:execute',
    'config:write',
    'schedule:configure',
  });
}

Set<String> _productsPermissions(AuthController authController) {
  return _permissions(authController, const {
    'crawl:execute',
    'product:write',
    'product:delete',
    'schedule:configure',
  });
}

Set<String> _schedulePermissions(AuthController authController) {
  return _permissions(authController, const {'schedule:configure'});
}

Set<String> _smartHomePermissions(AuthController authController) {
  return _permissions(authController, const {
    'smart_home:configure',
    'smart_home:control',
  });
}

Set<String> _permissions(AuthController authController, Set<String> names) {
  return {
    for (final name in names)
      if (authController.hasPermission(name)) name,
  };
}

Widget _permissionPage(
  AuthController authController,
  String permission,
  Widget child,
) {
  if (authController.hasPermission(permission)) {
    return child;
  }
  return PermissionDeniedPage(permission: permission);
}

class PermissionDeniedPage extends StatelessWidget {
  const PermissionDeniedPage({super.key, required this.permission});

  final String permission;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 44),
                const SizedBox(height: 16),
                Text(
                  'Permission required',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'This route needs $permission.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => context.go('/today'),
                  icon: const Icon(Icons.today),
                  label: const Text('Go to Today'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}
