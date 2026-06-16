import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

GoRouter createMavraRouter({required bool isAuthenticated}) {
  return GoRouter(
    initialLocation: isAuthenticated ? '/today' : '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final publicRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/auth/wechat/callback';

      if (!isAuthenticated && !publicRoute) {
        return '/login';
      }
      if (isAuthenticated &&
          (location == '/login' || location == '/register')) {
        return '/today';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/today'),
      GoRoute(path: '/login', builder: (context, state) => const LoginShell()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const PlaceholderScreen(title: 'Register'),
      ),
      GoRoute(
        path: '/auth/wechat/callback',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'WeChat Callback'),
      ),
      GoRoute(
        path: '/today',
        builder: (context, state) => const PlaceholderScreen(title: 'Today'),
      ),
    ],
  );
}

class LoginShell extends StatelessWidget {
  const LoginShell({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mavra',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mavra watches quietly',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.login),
                    label: const Text('Login'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('WeChat login'),
                  ),
                ],
              ),
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
