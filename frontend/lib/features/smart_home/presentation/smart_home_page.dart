import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/smart_home_models.dart';

class SmartHomePage extends StatefulWidget {
  const SmartHomePage({super.key, required this.repository});

  final SmartHomeRepository repository;

  @override
  State<SmartHomePage> createState() => _SmartHomePageState();
}

class _SmartHomePageState extends State<SmartHomePage> {
  Future<SmartHomeSnapshot>? _smartHomeFuture;
  SmartHomeSnapshot? _snapshot;
  List<SmartHomeEntityItem> _entities = const [];
  Object? _error;
  String? _statusMessage;
  bool _showConfigForm = false;
  bool _configEnabled = true;
  String _domainFilter = 'All';
  StreamSubscription<List<SmartHomeEntityItem>>? _entitySubscription;

  final _baseUrlController = TextEditingController();
  final _tokenController = TextEditingController();
  final _serviceEntityController = TextEditingController();
  final _serviceNameController = TextEditingController(text: 'turn_on');

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
    _serviceEntityController.dispose();
    _serviceNameController.dispose();
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
      _smartHomeFuture = Future.sync(widget.repository.loadSmartHome)
        ..then((snapshot) {
          if (mounted) {
            setState(() {
              _snapshot = snapshot;
              _entities = snapshot.entities;
            });
          }
        }).catchError((Object error) {
          if (mounted) {
            setState(() => _error = error);
          }
        });
    });
  }

  void _editConfig() {
    final config = _snapshot?.config;
    setState(() {
      _showConfigForm = true;
      _baseUrlController.text = config?.baseUrl ?? '';
      _tokenController.clear();
      _configEnabled = config?.enabled ?? true;
    });
  }

  Future<void> _saveConfig() async {
    final draft = SmartHomeConfigDraft(
      baseUrl: _baseUrlController.text.trim(),
      enabled: _configEnabled,
      token: _tokenController.text.trim(),
    );
    try {
      await widget.repository.saveConfig(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Saved Home Assistant config';
        _showConfigForm = false;
        _tokenController.clear();
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Save config failed');
      }
    }
  }

  Future<void> _callService() async {
    final draft = SmartHomeServiceDraft(
      entityId: _serviceEntityController.text.trim(),
      service: _serviceNameController.text.trim(),
    );
    try {
      final result = await widget.repository.callService(draft);
      if (mounted) {
        setState(() => _statusMessage = result.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Service call failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.home, label: 'Smart Home'),
          AdaptiveDestination(icon: Icons.schedule, label: 'Schedule'),
          AdaptiveDestination(icon: Icons.work, label: 'Jobs'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/schedule');
            case 3:
              context.go('/jobs');
            case 4:
              context.go('/analytics');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<SmartHomeSnapshot>(
              future: _smartHomeFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('智能家居状态加载失败。'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('正在连接 Home Assistant...'),
                      ],
                    ),
                  );
                }
                final current = _snapshot ?? const SmartHomeSnapshot.empty();
                return _SmartHomeContent(
                  snapshot: current,
                  entities: _filteredEntities(_entities),
                  allDomains: _domains(_entities),
                  selectedDomain: _domainFilter,
                  statusMessage: _statusMessage,
                  showConfigForm: _showConfigForm,
                  configEnabled: _configEnabled,
                  baseUrlController: _baseUrlController,
                  tokenController: _tokenController,
                  serviceEntityController: _serviceEntityController,
                  serviceNameController: _serviceNameController,
                  onEditConfig: current.canConfigure ? _editConfig : null,
                  onSaveConfig: _saveConfig,
                  onConfigEnabledChanged: (value) {
                    setState(() => _configEnabled = value ?? true);
                  },
                  onDomainSelected: (domain) {
                    setState(() => _domainFilter = domain);
                  },
                  onCallService: current.canControl ? _callService : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  List<SmartHomeEntityItem> _filteredEntities(
    List<SmartHomeEntityItem> entities,
  ) {
    if (_domainFilter == 'All') {
      return entities;
    }
    return entities.where((entity) => entity.domain == _domainFilter).toList();
  }

  List<String> _domains(List<SmartHomeEntityItem> entities) {
    final domains = entities.map((entity) => entity.domain).toSet().toList()
      ..sort();
    return ['All', ...domains];
  }
}

class _SmartHomeContent extends StatelessWidget {
  const _SmartHomeContent({
    required this.snapshot,
    required this.entities,
    required this.allDomains,
    required this.selectedDomain,
    required this.statusMessage,
    required this.showConfigForm,
    required this.configEnabled,
    required this.baseUrlController,
    required this.tokenController,
    required this.serviceEntityController,
    required this.serviceNameController,
    required this.onEditConfig,
    required this.onSaveConfig,
    required this.onConfigEnabledChanged,
    required this.onDomainSelected,
    required this.onCallService,
  });

  final SmartHomeSnapshot snapshot;
  final List<SmartHomeEntityItem> entities;
  final List<String> allDomains;
  final String selectedDomain;
  final String? statusMessage;
  final bool showConfigForm;
  final bool configEnabled;
  final TextEditingController baseUrlController;
  final TextEditingController tokenController;
  final TextEditingController serviceEntityController;
  final TextEditingController serviceNameController;
  final VoidCallback? onEditConfig;
  final Future<void> Function() onSaveConfig;
  final ValueChanged<bool?> onConfigEnabledChanged;
  final ValueChanged<String> onDomainSelected;
  final Future<void> Function()? onCallService;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Smart Home',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: onEditConfig,
                icon: const Icon(Icons.settings),
                label: const Text('Edit config'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_summaryText(snapshot)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: Icon(
                  snapshot.summary.connected
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                ),
                label: Text(
                  snapshot.summary.connected ? 'Connected' : 'Disconnected',
                ),
              ),
              Chip(label: Text('${snapshot.summary.activeCount} active')),
              Chip(
                label: Text(
                  'Unavailable devices ${snapshot.summary.unavailableCount}',
                ),
              ),
              if (!snapshot.realtimeConnected)
                const Chip(label: Text('Realtime disconnected')),
            ],
          ),
          if (!snapshot.canControl) ...[
            const SizedBox(height: 8),
            const Text('没有权限控制这个设备。'),
          ],
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          const SizedBox(height: 16),
          _ConfigSection(config: snapshot.config),
          if (showConfigForm) ...[
            const SizedBox(height: 12),
            _ConfigForm(
              enabled: configEnabled,
              baseUrlController: baseUrlController,
              tokenController: tokenController,
              onEnabledChanged: onConfigEnabledChanged,
              onSaveConfig: onSaveConfig,
            ),
          ],
          const SizedBox(height: 16),
          _ServiceForm(
            serviceEntityController: serviceEntityController,
            serviceNameController: serviceNameController,
            onCallService: onCallService,
          ),
          const SizedBox(height: 16),
          _DomainFilters(
            domains: allDomains,
            selectedDomain: selectedDomain,
            onSelected: onDomainSelected,
          ),
          const SizedBox(height: 12),
          if (snapshot.entities.isEmpty)
            const Center(child: Text('还没有可控制的 Home Assistant 设备。'))
          else
            for (final entity in entities) _EntityTile(entity: entity),
        ],
      ),
    );
  }

  static String _summaryText(SmartHomeSnapshot snapshot) {
    if (!snapshot.summary.configured) {
      return 'Home Assistant is not configured.';
    }
    if (!snapshot.summary.connected) {
      return '智能家居状态加载失败。';
    }
    return '家里设备都在安静运行。';
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.config});

  final SmartHomeConfig? config;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Home Assistant', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        if (config == null)
          const Text('No Home Assistant config')
        else
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(config!.baseUrl),
              Text(config!.enabled ? 'enabled' : 'disabled'),
              Text(
                config!.tokenConfigured ? 'token configured' : 'token missing',
              ),
              if (config!.lastStatus != null) Text(config!.lastStatus!),
            ],
          ),
      ],
    );
  }
}

class _ConfigForm extends StatelessWidget {
  const _ConfigForm({
    required this.enabled,
    required this.baseUrlController,
    required this.tokenController,
    required this.onEnabledChanged,
    required this.onSaveConfig,
  });

  final bool enabled;
  final TextEditingController baseUrlController;
  final TextEditingController tokenController;
  final ValueChanged<bool?> onEnabledChanged;
  final Future<void> Function() onSaveConfig;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Config form', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              key: const Key('smart-home-url-field'),
              controller: baseUrlController,
              decoration: const InputDecoration(labelText: 'Base URL'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('smart-home-token-field'),
              controller: tokenController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Token'),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: enabled,
              onChanged: onEnabledChanged,
              contentPadding: EdgeInsets.zero,
              title: const Text('Enabled'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onSaveConfig,
              icon: const Icon(Icons.save),
              label: const Text('Save config'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceForm extends StatelessWidget {
  const _ServiceForm({
    required this.serviceEntityController,
    required this.serviceNameController,
    required this.onCallService,
  });

  final TextEditingController serviceEntityController;
  final TextEditingController serviceNameController;
  final Future<void> Function()? onCallService;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service request',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('service-entity-field'),
              controller: serviceEntityController,
              decoration: const InputDecoration(labelText: 'Entity ID'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('service-name-field'),
              controller: serviceNameController,
              decoration: const InputDecoration(labelText: 'Service'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCallService,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Call service'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DomainFilters extends StatelessWidget {
  const _DomainFilters({
    required this.domains,
    required this.selectedDomain,
    required this.onSelected,
  });

  final List<String> domains;
  final String selectedDomain;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final domain in domains)
          ChoiceChip(
            label: Text(domain),
            selected: selectedDomain == domain,
            onSelected: (_) => onSelected(domain),
          ),
      ],
    );
  }
}

class _EntityTile extends StatelessWidget {
  const _EntityTile({required this.entity});

  final SmartHomeEntityItem entity;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(_iconForDomain(entity.domain)),
        title: Text(entity.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entity.entityId),
            if (entity.area != null) Text(entity.area!),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(label: Text(entity.domain)),
            Chip(label: Text(entity.state)),
            if (!entity.available)
              const Chip(
                avatar: Icon(Icons.warning_amber),
                label: Text('unavailable'),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForDomain(String domain) {
    switch (domain) {
      case 'light':
        return Icons.lightbulb;
      case 'switch':
        return Icons.toggle_on;
      case 'climate':
        return Icons.thermostat;
      case 'fan':
        return Icons.air;
      default:
        return Icons.home;
    }
  }
}
