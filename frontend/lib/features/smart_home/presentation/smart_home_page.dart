import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/notifications/mavra_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
import '../domain/smart_home_models.dart';

// Button styles are defined in MavraButtonStyle

class SmartHomePage extends StatefulWidget {
  const SmartHomePage({super.key, required this.repository, this.permissions});

  final SmartHomeRepository repository;
  final Set<String>? permissions;

  @override
  State<SmartHomePage> createState() => _SmartHomePageState();
}

class _SmartHomePageState extends State<SmartHomePage> {
  Future<SmartHomeSnapshot>? _smartHomeFuture;
  SmartHomeSnapshot? _snapshot;
  List<SmartHomeEntityItem> _entities = const [];
  Object? _error;
  bool _refreshing = false;
  StreamSubscription<List<SmartHomeEntityItem>>? _entitySubscription;

  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();

  bool get _canConfigure =>
      widget.permissions?.contains('smart_home:configure') ??
      (_snapshot?.canConfigure ?? true);

  bool get _canControl =>
      widget.permissions?.contains('smart_home:control') ??
      (_snapshot?.canControl ?? true);

  @override
  void initState() {
    super.initState();
    _subscribeToEntities();
    _load();
  }

  @override
  void didUpdateWidget(covariant SmartHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _entitySubscription?.cancel();
      _snapshot = null;
      _entities = const [];
      _subscribeToEntities();
      _load();
    }
  }

  @override
  void dispose() {
    _entitySubscription?.cancel();
    _baseUrlController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _subscribeToEntities() {
    _entitySubscription = widget.repository.watchEntities().listen((entities) {
      if (mounted) {
        setState(() => _entities = entities);
      }
    });
  }

  void _load() {
    setState(() {
      _error = null;
      _refreshing = true;
      _smartHomeFuture = _fetchSmartHome();
    });
  }

  Future<SmartHomeSnapshot> _fetchSmartHome() async {
    try {
      final snapshot = await widget.repository.loadSmartHome();
      if (mounted) {
        setState(() {
          _snapshot = snapshot;
          _entities = snapshot.entities;
        });
      }
      return snapshot;
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _openConfigDialog() async {
    final config = _snapshot?.config;
    _baseUrlController.text = config?.baseUrl ?? '';
    _tokenController.clear();
    var enabled = config?.enabled ?? true;
    var testing = false;
    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            SmartHomeConfigDraft draft() {
              final token = _tokenController.text.trim();
              return SmartHomeConfigDraft(
                baseUrl: _baseUrlController.text.trim(),
                enabled: enabled,
                token: token.isEmpty ? null : token,
              );
            }

            Future<void> testConfig() async {
              setDialogState(() => testing = true);
              try {
                final result = await widget.repository.testConfig(draft());
                if (!context.mounted) {
                  return;
                }
                MavraNotifier.success(result.message);
              } catch (_) {
                if (context.mounted) {
                  MavraNotifier.error('Failed to test smart home config');
                }
              } finally {
                if (context.mounted) {
                  setDialogState(() => testing = false);
                }
              }
            }

            Future<void> saveConfig() async {
              setDialogState(() => saving = true);
              try {
                await widget.repository.saveConfig(draft());
                if (!mounted || !dialogContext.mounted) {
                  return;
                }
                MavraNotifier.success('Smart home config saved');
                Navigator.of(dialogContext).pop();
                _load();
              } catch (_) {
                if (dialogContext.mounted) {
                  MavraNotifier.error('Failed to save smart home config');
                }
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              key: const Key('smart-home-config-dialog'),
              title: const Text('Home Assistant'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        key: const Key('smart-home-url-field'),
                        controller: _baseUrlController,
                        decoration: MavraInputStyle.filterInput(
                          context: context,
                          label: 'Base URL',
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        key: const Key('smart-home-token-field'),
                        controller: _tokenController,
                        obscureText: true,
                        decoration: MavraInputStyle.filterInput(
                          context: context,
                          label: config?.tokenConfigured == true
                              ? 'New Token'
                              : 'Long-Lived Access Token',
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Enabled'),
                        value: enabled,
                        onChanged: (value) {
                          setDialogState(() => enabled = value);
                        },
                      ),
                      OutlinedButton(
                        key: const Key('smart-home-test-config-button'),
                        style: MavraButtonStyle.compactOutlined(
                          context: context,
                        ),
                        onPressed: testing ? null : testConfig,
                        child: Text(testing ? 'Testing...' : 'Test Connection'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('smart-home-save-config-button'),
                  style: MavraButtonStyle.compactFilled(context: context),
                  onPressed: saving ? null : saveConfig,
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _callEntityService(
    SmartHomeEntityItem entity,
    String service, {
    Map<String, Object?> serviceData = const {},
  }) async {
    try {
      final result = await widget.repository.callService(
        SmartHomeServiceDraft(
          entityId: entity.entityId,
          service: service,
          serviceData: serviceData,
        ),
      );
      if (mounted) {
        setState(() {
          _entities = [
            for (final current in _entities)
              current.entityId == entity.entityId
                  ? _entityAfterService(current, service, serviceData)
                  : current,
          ];
        });
        MavraNotifier.success(result.message);
      }
    } catch (_) {
      if (mounted) {
        MavraNotifier.error('Command failed');
      }
    }
  }

  SmartHomeEntityItem _entityAfterService(
    SmartHomeEntityItem entity,
    String service,
    Map<String, Object?> serviceData,
  ) {
    switch (service) {
      case 'turn_on':
        return entity.copyWith(state: 'on');
      case 'turn_off':
        return entity.copyWith(state: 'off');
      case 'set_hvac_mode':
        final mode = serviceData['hvac_mode'];
        return mode is String ? entity.copyWith(state: mode) : entity;
      case 'set_temperature':
        final temperature = serviceData['temperature'];
        return temperature is num
            ? entity.copyWith(
                attributes: {...entity.attributes, 'temperature': temperature},
              )
            : entity;
      default:
        return entity;
    }
  }

  Future<void> _confirmRunEntity(SmartHomeEntityItem entity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Run ${entity.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: Key('smart-home-confirm-${entity.entityId}-turn_on'),
            style: MavraButtonStyle.compactFilled(context: context),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _callEntityService(entity, 'turn_on');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<SmartHomeSnapshot>(
            future: _smartHomeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done &&
                  _snapshot == null) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Connecting to Home Assistant...'),
                    ],
                  ),
                );
              }
              final current = _snapshot ?? const SmartHomeSnapshot.empty();
              return _SmartHomeContent(
                snapshot: current,
                entities: _entities,
                canConfigure: _canConfigure,
                canControl: _canControl,
                loading: _refreshing,
                loadError: _error == null
                    ? null
                    : 'Failed to load smart home entities',
                onRefresh: _load,
                onConfigure: _canConfigure ? _openConfigDialog : null,
                onCallEntityService: _canControl ? _callEntityService : null,
                onConfirmRunEntity: _canControl ? _confirmRunEntity : null,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SmartHomeContent extends StatelessWidget {
  const _SmartHomeContent({
    required this.snapshot,
    required this.entities,
    required this.canConfigure,
    required this.canControl,
    required this.loading,
    required this.loadError,
    required this.onRefresh,
    required this.onConfigure,
    required this.onCallEntityService,
    required this.onConfirmRunEntity,
  });

  final SmartHomeSnapshot snapshot;
  final List<SmartHomeEntityItem> entities;
  final bool canConfigure;
  final bool canControl;
  final bool loading;
  final String? loadError;
  final VoidCallback onRefresh;
  final VoidCallback? onConfigure;
  final Future<void> Function(
    SmartHomeEntityItem entity,
    String service, {
    Map<String, Object?> serviceData,
  })?
  onCallEntityService;
  final Future<void> Function(SmartHomeEntityItem entity)? onConfirmRunEntity;

  @override
  Widget build(BuildContext context) {
    final groups = _groupEntities(entities);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SmartHomeHeader(),
          const SizedBox(height: 8),
          _SmartHomeActions(
            connected: snapshot.summary.connected,
            loading: loading,
            onRefresh: onRefresh,
            onConfigure: onConfigure,
          ),
          const SizedBox(height: 24),
          if (loadError != null) ...[
            _MessageCard(message: loadError!, error: true),
            const SizedBox(height: 16),
          ],
          if (!canControl) ...[
            const Text('You do not have permission to control devices.'),
            const SizedBox(height: 16),
          ],
          if (groups.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Text('No supported Home Assistant entities found'),
              ),
            )
          else
            for (final group in groups.entries) ...[
              Text(group.key, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _EntityGrid(
                entities: group.value,
                canControl: canControl,
                onCallEntityService: onCallEntityService,
                onConfirmRunEntity: onConfirmRunEntity,
              ),
              const SizedBox(height: 24),
            ],
        ],
      ),
    );
  }

  static Map<String, List<SmartHomeEntityItem>> _groupEntities(
    List<SmartHomeEntityItem> entities,
  ) {
    final groups = <String, List<SmartHomeEntityItem>>{};
    final primaryDeviceNames = _primaryDeviceNames(entities);
    for (final entity in entities) {
      groups
          .putIfAbsent(_deviceName(entity, primaryDeviceNames), () => [])
          .add(entity);
    }
    return groups;
  }

  static String _deviceName(
    SmartHomeEntityItem entity,
    Map<String, String> primaryDeviceNames,
  ) {
    final area = entity.area?.trim();
    if (area != null && area.isNotEmpty) {
      return area;
    }
    final body = _entityBody(entity.entityId);
    if (body != null) {
      final matchingPrefix = _longestMatchingPrefix(body, primaryDeviceNames);
      if (matchingPrefix != null) {
        return primaryDeviceNames[matchingPrefix]!;
      }
    }
    if (entity.domain == 'scene' || entity.domain == 'script') {
      return entity.name;
    }
    final parts = entity.name.split(' ');
    if (parts.length <= 1) {
      return entity.name;
    }
    return parts.take(parts.length - 1).join(' ');
  }

  static Map<String, String> _primaryDeviceNames(
    List<SmartHomeEntityItem> entities,
  ) {
    final names = <String, String>{};
    for (final entity in entities) {
      if (!_isPrimaryDevice(entity.domain)) {
        continue;
      }
      final body = _entityBody(entity.entityId);
      if (body == null) {
        continue;
      }
      names[_primaryDevicePrefix(body)] = entity.name;
    }
    return names;
  }

  static bool _isPrimaryDevice(String domain) {
    return domain == 'climate' || domain == 'fan' || domain == 'cover';
  }

  static String? _entityBody(String entityId) {
    final dot = entityId.indexOf('.');
    if (dot < 0 || dot == entityId.length - 1) {
      return null;
    }
    return entityId.substring(dot + 1);
  }

  static String _primaryDevicePrefix(String body) {
    const suffixes = [
      '_air_conditioner',
      '_air_purifier',
      '_fan',
      '_cover',
      '_curtain',
      '_garage',
    ];
    for (final suffix in suffixes) {
      if (body.endsWith(suffix)) {
        return body.substring(0, body.length - suffix.length);
      }
    }
    final lastUnderscore = body.lastIndexOf('_');
    return lastUnderscore > 0 ? body.substring(0, lastUnderscore) : body;
  }

  static String? _longestMatchingPrefix(
    String body,
    Map<String, String> primaryDeviceNames,
  ) {
    String? match;
    for (final prefix in primaryDeviceNames.keys) {
      if ((body == prefix || body.startsWith('${prefix}_')) &&
          (match == null || prefix.length > match.length)) {
        match = prefix;
      }
    }
    return match;
  }
}

class _SmartHomeHeader extends StatelessWidget {
  const _SmartHomeHeader();

  @override
  Widget build(BuildContext context) {
    return const MavraPageBanner(
      key: Key('smart-home-title-banner'),
      accentColor: AppTheme.brandCyan,
      eyebrow: 'Smart Home',
      title: 'Smart Home',
      subtitle: 'Home Assistant devices and scenes',
    );
  }
}

class _SmartHomeActions extends StatelessWidget {
  const _SmartHomeActions({
    required this.connected,
    required this.loading,
    required this.onRefresh,
    required this.onConfigure,
  });

  final bool connected;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback? onConfigure;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: compact ? WrapAlignment.start : WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(connected ? 'Connected' : 'Offline'),
                avatar: Icon(
                  connected ? Icons.cloud_done : Icons.cloud_off,
                  size: 18,
                ),
              ),
              OutlinedButton(
                key: const Key('smart-home-refresh-button'),
                style: MavraButtonStyle.compactOutlined(context: context),
                onPressed: loading ? null : onRefresh,
                child: Text(loading ? 'Refreshing' : 'Refresh'),
              ),
              if (onConfigure != null)
                OutlinedButton.icon(
                  key: const Key('smart-home-configure-button'),
                  style: MavraButtonStyle.compactOutlined(context: context),
                  onPressed: onConfigure,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Configure'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.error});

  final String message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: TextStyle(color: error ? scheme.error : null),
        ),
      ),
    );
  }
}

class _EntityGrid extends StatelessWidget {
  const _EntityGrid({
    required this.entities,
    required this.canControl,
    required this.onCallEntityService,
    required this.onConfirmRunEntity,
  });

  final List<SmartHomeEntityItem> entities;
  final bool canControl;
  final Future<void> Function(
    SmartHomeEntityItem entity,
    String service, {
    Map<String, Object?> serviceData,
  })?
  onCallEntityService;
  final Future<void> Function(SmartHomeEntityItem entity)? onConfirmRunEntity;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1120
            ? 4
            : width >= 860
            ? 3
            : width >= 560
            ? 2
            : 1;
        final spacing = 16.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entity in entities)
              SizedBox(
                width: cardWidth,
                child: _EntityCard(
                  entity: entity,
                  canControl: canControl,
                  onCallEntityService: onCallEntityService,
                  onConfirmRunEntity: onConfirmRunEntity,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EntityCard extends StatelessWidget {
  const _EntityCard({
    required this.entity,
    required this.canControl,
    required this.onCallEntityService,
    required this.onConfirmRunEntity,
  });

  final SmartHomeEntityItem entity;
  final bool canControl;
  final Future<void> Function(
    SmartHomeEntityItem entity,
    String service, {
    Map<String, Object?> serviceData,
  })?
  onCallEntityService;
  final Future<void> Function(SmartHomeEntityItem entity)? onConfirmRunEntity;

  bool get _canUseAvailableControl =>
      entity.available && canControl && onCallEntityService != null;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: Key('smart-home-card-${entity.entityId}'),
      decoration: MavraTableStyle.panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconForDomain(entity.domain), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entity.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(label: Text(entity.state)),
              ],
            ),
            const SizedBox(height: 8),
            Text(entity.entityId, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            _controls(context),
            if (!entity.available) ...[
              const SizedBox(height: 12),
              const Chip(
                avatar: Icon(Icons.warning_amber, size: 18),
                label: Text('unavailable'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _controls(BuildContext context) {
    switch (entity.domain) {
      case 'light':
      case 'switch':
      case 'fan':
        return Switch(
          key: Key('smart-home-toggle-${entity.entityId}'),
          value: entity.state == 'on',
          onChanged: _canUseAvailableControl
              ? (_) => onCallEntityService!(
                  entity,
                  entity.state == 'on' ? 'turn_off' : 'turn_on',
                )
              : null,
        );
      case 'cover':
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              key: Key('smart-home-cover-open-${entity.entityId}'),
              style: MavraButtonStyle.compactOutlined(context: context),
              onPressed: canControl && onCallEntityService != null
                  ? () => onCallEntityService!(entity, 'open_cover')
                  : null,
              child: const Text('Open'),
            ),
            OutlinedButton(
              key: Key('smart-home-cover-stop-${entity.entityId}'),
              style: MavraButtonStyle.compactOutlined(context: context),
              onPressed: canControl && onCallEntityService != null
                  ? () => onCallEntityService!(entity, 'stop_cover')
                  : null,
              child: const Text('Stop'),
            ),
            OutlinedButton(
              key: Key('smart-home-cover-close-${entity.entityId}'),
              style: MavraButtonStyle.compactOutlined(context: context),
              onPressed: canControl && onCallEntityService != null
                  ? () => onCallEntityService!(entity, 'close_cover')
                  : null,
              child: const Text('Close'),
            ),
          ],
        );
      case 'climate':
        return _ClimateControls(
          entity: entity,
          enabled: _canUseAvailableControl,
          onCallEntityService: onCallEntityService,
        );
      case 'scene':
      case 'script':
        return FilledButton.icon(
          key: Key('smart-home-run-${entity.entityId}'),
          style: MavraButtonStyle.compactFilled(context: context),
          onPressed: canControl && onConfirmRunEntity != null
              ? () => onConfirmRunEntity!(entity)
              : null,
          icon: const Icon(Icons.power_settings_new, size: 18),
          label: const Text('Run'),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  static IconData _iconForDomain(String domain) {
    switch (domain) {
      case 'light':
        return Icons.lightbulb;
      case 'switch':
        return Icons.toggle_on;
      case 'fan':
        return Icons.air;
      case 'cover':
        return Icons.garage;
      case 'climate':
        return Icons.thermostat;
      case 'scene':
      case 'script':
        return Icons.play_circle;
      default:
        return Icons.home;
    }
  }
}

class _ClimateControls extends StatelessWidget {
  const _ClimateControls({
    required this.entity,
    required this.enabled,
    required this.onCallEntityService,
  });

  final SmartHomeEntityItem entity;
  final bool enabled;
  final Future<void> Function(
    SmartHomeEntityItem entity,
    String service, {
    Map<String, Object?> serviceData,
  })?
  onCallEntityService;

  @override
  Widget build(BuildContext context) {
    final modes = _stringList(entity.attributes['hvac_modes']);
    final temperature = _number(entity.attributes['temperature']);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 120,
          child: DropdownButtonFormField<String>(
            key: Key('smart-home-climate-mode-${entity.entityId}'),
            isExpanded: true,
            initialValue: modes.contains(entity.state)
                ? entity.state
                : (modes.isEmpty ? null : modes.first),
            decoration: MavraInputStyle.tableInput(context: context),
            items: [
              for (final mode in modes)
                DropdownMenuItem(value: mode, child: Text(mode)),
            ],
            onChanged: enabled && onCallEntityService != null
                ? (mode) {
                    if (mode != null) {
                      onCallEntityService!(
                        entity,
                        'set_hvac_mode',
                        serviceData: {'hvac_mode': mode},
                      );
                    }
                  }
                : null,
          ),
        ),
        SizedBox(
          width: 110,
          child: TextFormField(
            key: Key('smart-home-temperature-${entity.entityId}'),
            initialValue: temperature?.toString() ?? '',
            enabled: enabled && onCallEntityService != null,
            keyboardType: TextInputType.number,
            decoration: MavraInputStyle.tableInput(
              context: context,
              suffixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Text('C', style: TextStyle(fontSize: 13)),
              ),
            ),
            onFieldSubmitted: (value) {
              final next = double.tryParse(value.trim());
              if (next != null && onCallEntityService != null) {
                onCallEntityService!(
                  entity,
                  'set_temperature',
                  serviceData: {'temperature': next},
                );
              }
            },
          ),
        ),
      ],
    );
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value.whereType<String>().toList();
    }
    return const [];
  }

  static num? _number(Object? value) {
    return value is num ? value : null;
  }
}
