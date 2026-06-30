import 'package:flutter/material.dart';

import '../../../core/notifications/mavra_notifier.dart';
import '../domain/auth_models.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.authController});

  final AuthController authController;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<AccountOverview>? _overviewFuture;
  AccountOverview? _overview;
  Object? _loadError;
  int _loadRequestId = 0;
  String? _profileError;
  String? _passwordError;
  bool _savingProfile = false;
  bool _changingPassword = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authController != widget.authController) {
      _load();
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  void _load() {
    final requestId = ++_loadRequestId;
    final future = Future.sync(widget.authController.loadAccountOverview);
    setState(() {
      _overview = null;
      _loadError = null;
      _overviewFuture = future;
    });
    future
        .then((overview) {
          if (!mounted || requestId != _loadRequestId) {
            return;
          }
          setState(() {
            _overview = overview;
            _applyProfile(overview.profile);
          });
        })
        .catchError((Object error) {
          if (mounted && requestId == _loadRequestId) {
            setState(() => _loadError = error);
          }
        });
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    if (username.length < 3) {
      setState(() {
        _profileError = 'Username must be at least 3 characters';
      });
      return;
    }
    if (!email.contains('@')) {
      setState(() {
        _profileError = 'Email must be valid';
      });
      return;
    }

    setState(() {
      _savingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await widget.authController.updateProfile(
        AccountProfileDraft(username: username, email: email),
      );
      if (!mounted) {
        return;
      }
      final current = _overview;
      setState(() {
        _overview = AccountOverview(
          profile: profile,
          sessions: current?.sessions ?? const [],
          loginHistory: current?.loginHistory ?? const [],
        );
        _applyProfile(profile);
      });
      MavraNotifier.success('Profile updated successfully');
    } catch (error) {
      if (mounted) {
        setState(() => _profileError = 'Profile update failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        _passwordError = 'Current and new password are required';
      });
      return;
    }
    if (newPassword.length < 8) {
      setState(() {
        _passwordError = 'New password must be at least 8 characters';
      });
      return;
    }

    setState(() {
      _changingPassword = true;
      _passwordError = null;
    });
    try {
      await widget.authController.changePassword(
        PasswordChangeDraft(
          currentPassword: currentPassword,
          newPassword: newPassword,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentPasswordController.clear();
        _newPasswordController.clear();
      });
      MavraNotifier.success('Password changed successfully');
    } catch (error) {
      if (mounted) {
        setState(() => _passwordError = 'Password change failed.');
      }
    } finally {
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<AccountOverview>(
        future: _overviewFuture,
        builder: (context, snapshot) {
          if (_loadError != null) {
            return Center(child: Text('Profile failed: $_loadError'));
          }
          if (snapshot.connectionState != ConnectionState.done &&
              _overview == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Profile failed: ${snapshot.error}'));
          }
          final overview = _overview ?? snapshot.requireData;
          return ListView(
            key: const Key('profile-page-list'),
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Personal Info',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _AccountSummary(profile: overview.profile),
              const SizedBox(height: 16),
              _EditProfileSection(
                usernameController: _usernameController,
                emailController: _emailController,
                errorText: _profileError,
                isSaving: _savingProfile,
                onSave: _saveProfile,
              ),
              const SizedBox(height: 16),
              _PasswordSection(
                currentPasswordController: _currentPasswordController,
                newPasswordController: _newPasswordController,
                errorText: _passwordError,
                isSaving: _changingPassword,
                onSave: _changePassword,
              ),
              const SizedBox(height: 24),
              _SessionsSection(sessions: overview.sessions),
              const SizedBox(height: 24),
              _LoginHistorySection(entries: overview.loginHistory),
            ],
          );
        },
      ),
    );
  }

  void _applyProfile(AccountProfile profile) {
    _usernameController.text = profile.username;
    _emailController.text = profile.email;
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary({required this.profile});

  final AccountProfile profile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Account Info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(profile.username),
            const SizedBox(height: 8),
            Text(profile.email),
            if (profile.role != null) ...[
              const SizedBox(height: 8),
              Text('Role: ${profile.role}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditProfileSection extends StatelessWidget {
  const _EditProfileSection({
    required this.usernameController,
    required this.emailController,
    required this.errorText,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController usernameController;
  final TextEditingController emailController;
  final String? errorText;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit personal info',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 240,
                  child: TextField(
                    key: const Key('profile-username-field'),
                    controller: usernameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                ),
                SizedBox(
                  width: 300,
                  child: TextField(
                    key: const Key('profile-email-field'),
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('profile-save-button'),
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ],
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PasswordSection extends StatelessWidget {
  const _PasswordSection({
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.errorText,
    required this.isSaving,
    required this.onSave,
  });

  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final String? errorText;
  final bool isSaving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Change Password',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('profile-current-password-field'),
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                    ),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('profile-new-password-field'),
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                  ),
                ),
                FilledButton.icon(
                  key: const Key('profile-change-password-button'),
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_reset),
                  label: const Text('Change Password'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Use at least 8 characters for the new password.'),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!, style: TextStyle(color: Colors.red.shade700)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SessionsSection extends StatelessWidget {
  const _SessionsSection({required this.sessions});

  final List<AccountSession> sessions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sessions'),
        const SizedBox(height: 8),
        for (final session in sessions)
          Card(
            child: ListTile(
              leading: const Icon(Icons.devices),
              title: Text(session.device ?? 'Unknown device'),
              subtitle: Text('Last active: ${session.lastActiveAt.toLocal()}'),
            ),
          ),
        if (sessions.isEmpty)
          const ListTile(
            leading: Icon(Icons.devices),
            title: Text('No active sessions'),
          ),
      ],
    );
  }
}

class _LoginHistorySection extends StatelessWidget {
  const _LoginHistorySection({required this.entries});

  final List<LoginHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Login history'),
        const SizedBox(height: 8),
        for (final entry in entries)
          Card(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: Text(entry.ipAddress ?? 'Unknown IP'),
              subtitle: Text(entry.userAgent ?? 'Unknown client'),
            ),
          ),
        if (entries.isEmpty)
          const ListTile(
            leading: Icon(Icons.history),
            title: Text('No login history'),
          ),
      ],
    );
  }
}
