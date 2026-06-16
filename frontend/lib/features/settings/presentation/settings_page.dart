import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/settings_models.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.repository,
    this.config = AppConfig.current,
    this.capabilities,
    this.permissions = const {'config:read', 'config:write'},
  });

  final SettingsRepository repository;
  final AppConfig config;
  final PlatformCapabilities? capabilities;
  final Set<String> permissions;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<SettingsSnapshot>? _settingsFuture;
  SettingsSnapshot? _snapshot;
  Object? _error;
  String? _statusMessage;
  String? _retentionError;
  String _themeMode = 'system';

  final _retentionController = TextEditingController();
  final _feishuController = TextEditingController();

  PlatformCapabilities get _capabilities =>
      widget.capabilities ?? PlatformCapabilities.current();

  bool get _canRead => widget.permissions.contains('config:read');

  bool get _canWrite => widget.permissions.contains('config:write');

  @override
  void initState() {
    super.initState();
    if (_canRead) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.permissions != widget.permissions) {
      _snapshot = null;
      if (_canRead) {
        _load();
      }
    }
  }

  @override
  void dispose() {
    _retentionController.dispose();
    _feishuController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _error = null;
      _settingsFuture = Future.sync(widget.repository.loadSettings)
        ..then((snapshot) {
          if (!mounted) {
            return;
          }
          setState(() {
            _snapshot = snapshot;
            _themeMode = _knownTheme(snapshot.themeMode);
            _applySnapshot(snapshot);
          });
        }).catchError((Object error) {
          if (mounted) {
            setState(() => _error = error);
          }
        });
    });
  }

  Future<void> _saveSettings() async {
    final parsedRetention = int.tryParse(_retentionController.text.trim());
    if (parsedRetention == null ||
        parsedRetention < 1 ||
        parsedRetention > 3650) {
      setState(() {
        _retentionError = 'Retention must be between 1 and 3650 days';
        _statusMessage = null;
      });
      return;
    }

    final draft = SettingsDraft(
      dataRetentionDays: parsedRetention,
      feishuWebhookUrl: _blankToNull(_feishuController.text),
      themeMode: _themeMode,
    );

    try {
      final snapshot = await widget.repository.saveSettings(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshot = snapshot;
        _retentionError = null;
        _statusMessage = 'Saved settings';
        _themeMode = _knownTheme(snapshot.themeMode);
        _applySnapshot(snapshot);
      });
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Settings save failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRead) {
      return const _SettingsPermissionDenied();
    }

    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
          AdaptiveDestination(icon: Icons.people, label: 'Admin'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/analytics');
            case 3:
              context.go('/admin/users');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<SettingsSnapshot>(
              future: _settingsFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('设置加载失败。'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('正在加载设置...'),
                      ],
                    ),
                  );
                }

                return _SettingsContent(
                  snapshot: _snapshot ?? const SettingsSnapshot.empty(),
                  config: widget.config,
                  capabilities: _capabilities,
                  canWrite: _canWrite,
                  retentionController: _retentionController,
                  feishuController: _feishuController,
                  retentionError: _retentionError,
                  statusMessage: _statusMessage,
                  themeMode: _themeMode,
                  onSaveSettings: _saveSettings,
                  onThemeChanged: (selection) {
                    setState(() {
                      _themeMode = selection.first;
                    });
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _applySnapshot(SettingsSnapshot snapshot) {
    final config = snapshot.userConfig;
    if (config == null) {
      _retentionController.clear();
      _feishuController.clear();
      return;
    }
    _retentionController.text = config.dataRetentionDays.toString();
    _feishuController.text = config.feishuWebhookUrl ?? '';
  }

  static String _knownTheme(String value) {
    return _themeModes.contains(value) ? value : 'system';
  }

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

const _themeModes = ['system', 'light', 'dark'];

class _SettingsPermissionDenied extends StatelessWidget {
  const _SettingsPermissionDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 44),
              const SizedBox(height: 16),
              const Text('没有权限修改这些设置。'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/today'),
                icon: const Icon(Icons.today),
                label: const Text('回到 Today'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.snapshot,
    required this.config,
    required this.capabilities,
    required this.canWrite,
    required this.retentionController,
    required this.feishuController,
    required this.retentionError,
    required this.statusMessage,
    required this.themeMode,
    required this.onSaveSettings,
    required this.onThemeChanged,
  });

  final SettingsSnapshot snapshot;
  final AppConfig config;
  final PlatformCapabilities capabilities;
  final bool canWrite;
  final TextEditingController retentionController;
  final TextEditingController feishuController;
  final String? retentionError;
  final String? statusMessage;
  final String themeMode;
  final Future<void> Function() onSaveSettings;
  final ValueChanged<Set<String>> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final userConfig = snapshot.userConfig;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Settings', style: Theme.of(context).textTheme.headlineSmall),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          const SizedBox(height: 16),
          if (snapshot.isEmpty)
            const Text('还没有可配置的偏好。')
          else ...[
            Text('User config', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(userConfig!.username),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    key: const Key('settings-retention-field'),
                    controller: retentionController,
                    enabled: canWrite,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Data retention days',
                      errorText: retentionError,
                    ),
                  ),
                ),
                SizedBox(
                  width: 360,
                  child: TextField(
                    key: const Key('settings-feishu-field'),
                    controller: feishuController,
                    enabled: canWrite,
                    decoration: const InputDecoration(
                      labelText: 'Feishu webhook URL',
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: canWrite ? onSaveSettings : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save settings'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text('Theme', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'system', label: Text('System')),
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'dark', label: Text('Dark')),
            ],
            selected: {themeMode},
            onSelectionChanged: onThemeChanged,
          ),
          const SizedBox(height: 8),
          Text('Theme preference: $themeMode'),
          const SizedBox(height: 20),
          Text(
            'API Environment',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(config.apiBaseUrl),
          const SizedBox(height: 20),
          Text(
            'Platform permissions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                label: Text(
                  'File picker: ${_availability(capabilities.canPickFiles)}',
                ),
              ),
              Chip(
                label: Text(
                  'Save dialog: ${_availability(capabilities.supportsSaveDialog)}',
                ),
              ),
              Chip(
                label: Text(
                  'Downloads: ${_availability(capabilities.canDownloadFiles)}',
                ),
              ),
              Chip(
                label: Text(
                  'Secure storage: ${capabilities.secureStorageMode.name}',
                ),
              ),
              Chip(label: Text('Realtime: ${capabilities.realtimeMode.name}')),
            ],
          ),
        ],
      ),
    );
  }

  static String _availability(bool value) {
    return value ? 'available' : 'unavailable';
  }
}
