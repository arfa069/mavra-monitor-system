import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class MavraApp extends StatelessWidget {
  const MavraApp({
    super.key,
    this.config = AppConfig.current,
    this.isAuthenticated = false,
  });

  final AppConfig config;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final router = createMavraRouter(isAuthenticated: isAuthenticated);

    return MaterialApp.router(
      title: 'Mavra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
