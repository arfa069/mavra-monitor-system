import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/domain/auth_models.dart';

class MavraShell extends StatelessWidget {
  const MavraShell({
    super.key,
    required this.authController,
    required this.child,
  });

  final AuthController authController;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final destinations = _destinations(authController);
    final selectedIndex = _selectedIndex(
      destinations,
      GoRouterState.of(context).uri.path,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        return Scaffold(
          appBar: compact
              ? AppBar(
                  title: const Text('Mavra'),
                  actions: [
                    _ShellUserMenu(authController: authController),
                  ],
                )
              : null,
          drawer: compact
              ? NavigationDrawer(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) {
                    Navigator.of(context).pop();
                    context.go(destinations[index].route);
                  },
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(28, 20, 16, 12),
                      child: Text('Mavra'),
                    ),
                    for (final destination in destinations)
                      NavigationDrawerDestination(
                        key: Key('app-shell-nav-${destination.route}'),
                        icon: Icon(destination.icon),
                        label: Text(destination.label),
                      ),
                  ],
                )
              : null,
          body: compact
              ? child
              : Row(
                  children: [
                    SizedBox(
                      width: 200,
                      child: Material(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text('Mavra'),
                              ),
                            ),
                            Expanded(
                              child: ListView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                children: [
                                  for (var i = 0; i < destinations.length; i++)
                                    _ShellNavTile(
                                      key: Key(
                                        'app-shell-nav-${destinations[i].route}',
                                      ),
                                      destination: destinations[i],
                                      selected: i == selectedIndex,
                                      onTap: () =>
                                          context.go(destinations[i].route),
                                    ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: _ShellUserMenu(
                                authController: authController,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: child),
                  ],
                ),
        );
      },
    );
  }

  static List<_ShellDestination> _destinations(AuthController authController) {
    return [
      const _ShellDestination(
        route: '/today',
        label: 'Today',
        icon: Icons.today,
      ),
      const _ShellDestination(
        route: '/dashboard',
        label: 'Analytics',
        icon: Icons.analytics,
      ),
      const _ShellDestination(
        route: '/events',
        label: 'Activity',
        icon: Icons.event_note,
      ),
      const _ShellDestination(
        route: '/jobs',
        label: 'Jobs',
        icon: Icons.work,
      ),
      const _ShellDestination(
        route: '/products',
        label: 'Prices',
        icon: Icons.inventory_2,
      ),
      const _ShellDestination(
        route: '/schedule',
        label: 'Schedules',
        icon: Icons.schedule,
      ),
      const _ShellDestination(
        route: '/smart-home',
        label: 'Home',
        icon: Icons.home,
      ),
      if (authController.hasPermission('blog:read_admin'))
        const _ShellDestination(
          route: '/admin/blog',
          label: 'Blog',
          icon: Icons.article,
        ),
      if (authController.hasPermission('user:read')) ...const [
        _ShellDestination(
          route: '/admin/users',
          label: 'Users',
          icon: Icons.people,
        ),
        _ShellDestination(
          route: '/admin/audit-logs',
          label: 'Audit Logs',
          icon: Icons.receipt_long,
        ),
      ],
    ];
  }

  static int _selectedIndex(List<_ShellDestination> destinations, String path) {
    final normalized = path == '/analytics' ? '/dashboard' : path;
    final index = destinations.indexWhere(
      (destination) =>
          normalized == destination.route ||
          normalized.startsWith('${destination.route}/'),
    );
    return index < 0 ? 0 : index;
  }
}

class _ShellNavTile extends StatelessWidget {
  const _ShellNavTile({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final _ShellDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: selected,
      leading: Icon(destination.icon),
      title: Text(destination.label),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}

class _ShellUserMenu extends StatelessWidget {
  const _ShellUserMenu({required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          key: const Key('app-shell-user-profile'),
          leadingIcon: const Icon(Icons.person),
          child: const Text('Profile'),
          onPressed: () => context.go('/profile'),
        ),
        MenuItemButton(
          key: const Key('app-shell-user-settings'),
          leadingIcon: const Icon(Icons.settings),
          child: const Text('Account Settings'),
          onPressed: () => context.go('/settings'),
        ),
        if (authController.hasPermission('user:read')) ...[
          MenuItemButton(
            leadingIcon: const Icon(Icons.people),
            child: const Text('User Management'),
            onPressed: () => context.go('/admin/users'),
          ),
          MenuItemButton(
            leadingIcon: const Icon(Icons.receipt_long),
            child: const Text('Audit Logs'),
            onPressed: () => context.go('/admin/audit-logs'),
          ),
        ],
        MenuItemButton(
          key: const Key('app-shell-user-logout'),
          leadingIcon: const Icon(Icons.logout),
          child: const Text('Log Out'),
          onPressed: () async {
            await authController.logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
        ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          key: const Key('app-shell-user-menu'),
          tooltip: 'User menu',
          icon: const Icon(Icons.account_circle),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.route,
    required this.label,
    required this.icon,
  });

  final String route;
  final String label;
  final IconData icon;
}
