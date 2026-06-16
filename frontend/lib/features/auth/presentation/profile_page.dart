import 'package:flutter/material.dart';

import '../domain/auth_models.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<AccountOverview>(
        future: authController.loadAccountOverview(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Profile failed: ${snapshot.error}'));
          }
          final overview = snapshot.requireData;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                overview.profile.username,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(overview.profile.email),
              if (overview.profile.role != null) ...[
                const SizedBox(height: 8),
                Text('Role: ${overview.profile.role}'),
              ],
              const SizedBox(height: 24),
              const Text('Sessions'),
              const SizedBox(height: 8),
              for (final session in overview.sessions)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.devices),
                    title: Text(session.device ?? 'Unknown device'),
                    subtitle: Text(
                      'Last active: ${session.lastActiveAt.toLocal()}',
                    ),
                  ),
                ),
              if (overview.sessions.isEmpty)
                const ListTile(
                  leading: Icon(Icons.devices),
                  title: Text('No active sessions'),
                ),
              const SizedBox(height: 24),
              const Text('Login history'),
              const SizedBox(height: 8),
              for (final entry in overview.loginHistory)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(entry.ipAddress ?? 'Unknown IP'),
                    subtitle: Text(entry.userAgent ?? 'Unknown client'),
                  ),
                ),
              if (overview.loginHistory.isEmpty)
                const ListTile(
                  leading: Icon(Icons.history),
                  title: Text('No login history'),
                ),
            ],
          );
        },
      ),
    );
  }
}
