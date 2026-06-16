import 'package:flutter/material.dart';

import '../core/auth/auth_repository.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/data/auth_api.dart';
import '../features/auth/domain/auth_models.dart';
import 'router.dart';

class MavraApp extends StatelessWidget {
  const MavraApp({
    super.key,
    this.config = AppConfig.current,
    this.isAuthenticated = false,
    this.authController,
    this.initialLocation,
  });

  final AppConfig config;
  final bool isAuthenticated;
  final AuthController? authController;
  final String? initialLocation;

  @override
  Widget build(BuildContext context) {
    final controller = authController ?? _defaultAuthController();
    final router = createMavraRouter(
      authController: controller,
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
}
