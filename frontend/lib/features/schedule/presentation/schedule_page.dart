import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/mavra_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
import '../domain/schedule_models.dart';

enum _ScheduleWorkbenchTab { productTimers, jobTimers, settings }

extension _ScheduleWorkbenchTabMeta on _ScheduleWorkbenchTab {
  String get key => switch (this) {
    _ScheduleWorkbenchTab.productTimers => 'schedule-tab-product-timers',
    _ScheduleWorkbenchTab.jobTimers => 'schedule-tab-job-timers',
    _ScheduleWorkbenchTab.settings => 'schedule-tab-settings',
  };

  String get label => switch (this) {
    _ScheduleWorkbenchTab.productTimers => 'Product Timers',
    _ScheduleWorkbenchTab.jobTimers => 'Job Timers',
    _ScheduleWorkbenchTab.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    _ScheduleWorkbenchTab.productTimers => Icons.inventory_2_outlined,
    _ScheduleWorkbenchTab.jobTimers => Icons.work_outline,
    _ScheduleWorkbenchTab.settings => Icons.settings_outlined,
  };
}

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.repository, this.permissions});

  final ScheduleRepository repository;
  final Set<String>? permissions;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Future<ScheduleSnapshot>? _scheduleFuture;
  ScheduleSnapshot? _snapshot;
  Object? _error;
  int _loadRequestId = 0;
  String? _validationMessage;
  _ScheduleWorkbenchTab _activeTab = _ScheduleWorkbenchTab.productTimers;
  String? _addProductPlatform;

  final _retentionController = TextEditingController(text: '365');
  final _webhookController = TextEditingController();
  final _addProductCronController = TextEditingController();
  final _generatorInputController = TextEditingController();
  final _productCronControllers = <String, TextEditingController>{};
  final _jobCronControllers = <int, TextEditingController>{};

  bool get _canConfigure =>
      widget.permissions?.contains('schedule:configure') ??
      (_snapshot?.canConfigure ?? true);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant SchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _snapshot = null;
      _disposeScheduleControllers();
      _load();
    }
  }

  @override
  void dispose() {
    _retentionController.dispose();
    _webhookController.dispose();
    _addProductCronController.dispose();
    _generatorInputController.dispose();
    _disposeScheduleControllers();
    super.dispose();
  }

  void _disposeScheduleControllers() {
    for (final controller in _productCronControllers.values) {
      controller.dispose();
    }
    for (final controller in _jobCronControllers.values) {
      controller.dispose();
    }
    _productCronControllers.clear();
    _jobCronControllers.clear();
  }

  void _load() {
    final requestId = ++_loadRequestId;
    final future = Future.sync(widget.repository.loadSchedule);
    setState(() {
      _error = null;
      _scheduleFuture = future;
    });
    future
        .then((snapshot) {
          if (!mounted || requestId != _loadRequestId) {
            return;
          }
          setState(() {
            _snapshot = snapshot;
            _retentionController.text = '${snapshot.settings.retentionDays}';
            _webhookController.text = snapshot.settings.feishuWebhookUrl ?? '';
            _syncCronControllers(snapshot);
          });
        })
        .catchError((Object error) {
          if (mounted && requestId == _loadRequestId) {
            setState(() => _error = error);
          }
        });
  }

  void _syncCronControllers(ScheduleSnapshot snapshot) {
    final productPlatforms = {
      for (final schedule in snapshot.productSchedules) schedule.platform,
    };
    for (final platform in _productCronControllers.keys.toList()) {
      if (!productPlatforms.contains(platform)) {
        _productCronControllers.remove(platform)?.dispose();
      }
    }
    for (final schedule in snapshot.productSchedules) {
      _productCronControllers
              .putIfAbsent(schedule.platform, TextEditingController.new)
              .text =
          schedule.cronExpression;
    }

    final jobConfigIds = {
      for (final schedule in snapshot.jobSchedules) schedule.configId,
    };
    for (final configId in _jobCronControllers.keys.toList()) {
      if (!jobConfigIds.contains(configId)) {
        _jobCronControllers.remove(configId)?.dispose();
      }
    }
    for (final schedule in snapshot.jobSchedules) {
      _jobCronControllers
              .putIfAbsent(schedule.configId, TextEditingController.new)
              .text =
          schedule.cronExpression;
    }
  }

  TextEditingController _productCronController(ProductSchedule schedule) {
    return _productCronControllers.putIfAbsent(
      schedule.platform,
      TextEditingController.new,
    );
  }

  TextEditingController _jobCronController(JobSchedule schedule) {
    return _jobCronControllers.putIfAbsent(
      schedule.configId,
      TextEditingController.new,
    );
  }

  Future<void> _saveProductCron(ProductSchedule schedule) async {
    final cron = _productCronController(schedule).text.trim();
    if (!CronGenerator.isValidExpression(cron)) {
      setState(() => _validationMessage = 'Invalid cron expression');
      return;
    }
    try {
      await widget.repository.saveProductCron(
        platform: schedule.platform,
        cronExpression: cron.isEmpty ? null : cron,
        timezone: schedule.timezone,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _validationMessage = null;
      });
      MavraNotifier.success('Saved ${schedule.platform} schedule');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Save failed: $error');
      }
    }
  }

  Future<void> _deleteProductSchedule(ProductSchedule schedule) async {
    try {
      await widget.repository.deleteProductCron(schedule.platform);
      if (!mounted) {
        return;
      }
      setState(() {
        _validationMessage = null;
      });
      MavraNotifier.success('Deleted ${schedule.platform} schedule');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Delete failed: $error');
      }
    }
  }

  Future<void> _saveJobCron(JobSchedule schedule) async {
    final cron = _jobCronController(schedule).text.trim();
    if (!CronGenerator.isValidExpression(cron)) {
      setState(() => _validationMessage = 'Invalid cron expression');
      return;
    }
    try {
      await widget.repository.saveJobCron(
        configId: schedule.configId,
        cronExpression: cron.isEmpty ? null : cron,
        timezone: schedule.timezone,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _validationMessage = null;
      });
      MavraNotifier.success('Saved ${schedule.name} schedule');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Save failed: $error');
      }
    }
  }

  Future<void> _saveSettings() async {
    final retention = int.tryParse(_retentionController.text.trim());
    if (retention == null || retention < 1) {
      setState(() => _validationMessage = 'Retention must be at least 1 day');
      return;
    }
    try {
      await widget.repository.saveSettings(
        ScheduleSettings(
          retentionDays: retention,
          feishuWebhookUrl: _webhookController.text.trim().isEmpty
              ? null
              : _webhookController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _validationMessage = null;
      });
      MavraNotifier.success('Saved schedule settings');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Save failed: $error');
      }
    }
  }

  Future<void> _showAddProductDialog() async {
    _addProductPlatform = _firstAvailableProductPlatform();
    _addProductCronController.text = '0 9 * * *';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Add Product Crawl Timer'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  key: const Key('schedule-add-product-platform-field'),
                  initialValue: _addProductPlatform,
                  decoration: const InputDecoration(labelText: 'Platform'),
                  items: [
                    for (final platform in _productPlatformOptions())
                      DropdownMenuItem(
                        value: platform,
                        child: Text(_platformLabel(platform)),
                      ),
                  ],
                  onChanged: _canConfigure
                      ? (value) => setDialogState(() {
                          _addProductPlatform = value;
                        })
                      : null,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('schedule-add-product-cron-field'),
                  controller: _addProductCronController,
                  enabled: _canConfigure,
                  decoration: const InputDecoration(
                    labelText: 'Cron Expression',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              key: const Key('schedule-add-product-confirm-button'),
              onPressed: _canConfigure
                  ? () async {
                      final platform = _addProductPlatform;
                      final cron = _addProductCronController.text.trim();
                      if (platform == null || platform.isEmpty) {
                        setState(() {
                          _validationMessage = 'Platform is required';
                        });
                        return;
                      }
                      if (cron.isEmpty ||
                          !CronGenerator.isValidExpression(cron)) {
                        setState(() {
                          _validationMessage = 'Invalid cron expression';
                        });
                        return;
                      }
                      await widget.repository.createProductCron(
                        platform: platform,
                        cronExpression: cron,
                      );
                      if (!mounted) {
                        return;
                      }
                      Navigator.of(context, rootNavigator: true).pop();
                      setState(() {
                        _validationMessage = null;
                      });
                      MavraNotifier.success('Added $platform schedule');
                      _load();
                    }
                  : null,
              icon: const Icon(Icons.add),
              label: const Text('Add timer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCronGenerator(
    TextEditingController targetController,
  ) async {
    _generatorInputController.clear();
    String? generatedExpression;
    String? generatorError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Cron Expression Generator'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in CronGenerator.presets)
                        OutlinedButton(
                          onPressed: _canConfigure
                              ? () => setDialogState(() {
                                  generatedExpression = preset.expression;
                                  generatorError = null;
                                })
                              : null,
                          child: Text(preset.label),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('schedule-cron-generator-input'),
                    controller: _generatorInputController,
                    enabled: _canConfigure,
                    decoration: const InputDecoration(
                      labelText: 'Describe schedule',
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    key: const Key('schedule-cron-generator-generate-button'),
                    onPressed: _canConfigure
                        ? () {
                            final expression =
                                CronGenerator.fromNaturalLanguage(
                                  _generatorInputController.text,
                                );
                            setDialogState(() {
                              generatedExpression = expression;
                              generatorError = expression == null
                                  ? 'Could not parse schedule'
                                  : null;
                            });
                          }
                        : null,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate'),
                  ),
                  if (generatedExpression != null) ...[
                    const SizedBox(height: 12),
                    SelectableText(generatedExpression!),
                  ],
                  if (generatorError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      generatorError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              key: const Key('schedule-cron-generator-apply-button'),
              onPressed: _canConfigure && generatedExpression != null
                  ? () {
                      targetController.text = generatedExpression!;
                      Navigator.of(dialogContext).pop();
                    }
                  : null,
              icon: const Icon(Icons.check),
              label: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _productPlatformOptions() {
    final platforms = <String>{'taobao', 'jd', 'amazon'};
    for (final schedule in _snapshot?.productSchedules ?? const []) {
      platforms.add(schedule.platform);
    }
    return platforms.toList()..sort();
  }

  String? _firstAvailableProductPlatform() {
    final configured = {
      for (final schedule in _snapshot?.productSchedules ?? const [])
        schedule.platform,
    };
    for (final platform in const ['taobao', 'jd', 'amazon']) {
      if (!configured.contains(platform)) {
        return platform;
      }
    }
    final options = _productPlatformOptions();
    return options.isEmpty ? null : options.first;
  }

  Widget _buildContent(ScheduleSnapshot snapshot) {
    final canConfigure =
        widget.permissions?.contains('schedule:configure') ??
        snapshot.canConfigure;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ScheduleHeader(),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.autorenew),
                label: Text(snapshot.status.label),
              ),
              if (snapshot.status.timezone != null)
                Chip(
                  avatar: const Icon(Icons.public),
                  label: Text(snapshot.status.timezone!),
                ),
            ],
          ),
          if (!canConfigure) ...[
            const SizedBox(height: 8),
            const Text('没有权限修改自动规则。'),
          ],
          if (_validationMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 16),
          _ScheduleTabStrip(
            activeTab: _activeTab,
            onChanged: (tab) => setState(() => _activeTab = tab),
          ),
          const SizedBox(height: 16),
          switch (_activeTab) {
            _ScheduleWorkbenchTab.productTimers => _buildProductTimersTab(
              snapshot,
              canConfigure,
            ),
            _ScheduleWorkbenchTab.jobTimers => _buildJobTimersTab(
              snapshot,
              canConfigure,
            ),
            _ScheduleWorkbenchTab.settings => _buildSettingsTab(
              snapshot,
              canConfigure,
            ),
          },
        ],
      ),
    );
  }

  Widget _buildProductTimersTab(ScheduleSnapshot snapshot, bool canConfigure) {
    return _SchedulePanel(
      title: 'Product Crawl Schedule Config',
      trailing: FilledButton.icon(
        key: const Key('schedule-add-product-button'),
        style: MavraButtonStyle.compactFilled(context: context),
        onPressed: canConfigure ? _showAddProductDialog : null,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Product Timer'),
      ),
      child: MavraResponsiveDataView<ProductSchedule>(
        key: const Key('schedule-product-table'),
        rows: snapshot.productSchedules,
        wideBreakpoint: 760,
        empty: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No product schedule configs')),
        ),
        columns: const [
          DataColumn(label: Text('Platform')),
          DataColumn(label: Text('Cron Expression')),
          DataColumn(label: Text('Next Run')),
          DataColumn(label: Text('Actions')),
        ],
        tableCells: (schedule) => [
          DataCell(Text(schedule.platform)),
          DataCell(
            SizedBox(
              width: 160,
              child: TextField(
                key: Key('schedule-product-cron-${schedule.platform}-field'),
                controller: _productCronController(schedule),
                enabled: canConfigure,
                decoration: MavraInputStyle.tableInput(context: context),
              ),
            ),
          ),
          DataCell(Text(_nextRunTableLabel(schedule.nextRunAt))),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  key: Key('schedule-product-save-${schedule.platform}-button'),
                  style: MavraButtonStyle.compactOutlined(context: context),
                  onPressed: canConfigure
                      ? () => _saveProductCron(schedule)
                      : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: Key(
                    'schedule-product-generate-${schedule.platform}-button',
                  ),
                  tooltip: 'Generate cron',
                  style: MavraButtonStyle.rowIconButton(context: context),
                  onPressed: canConfigure
                      ? () =>
                            _showCronGenerator(_productCronController(schedule))
                      : null,
                  icon: const Icon(Icons.auto_awesome),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: Key(
                    'schedule-product-delete-${schedule.platform}-button',
                  ),
                  tooltip: 'Delete ${schedule.platform}',
                  style: MavraButtonStyle.rowIconButton(
                    context: context,
                    isDangerous: true,
                  ),
                  onPressed: canConfigure
                      ? () => _deleteProductSchedule(schedule)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ],
        mobileBuilder: (context, schedule) => _ScheduleTimerTile(
          title: schedule.platform,
          subtitle: _cronLabel(schedule.cronExpression),
          nextRunAt: schedule.nextRunAt,
          icon: Icons.inventory_2_outlined,
          cronField: TextField(
            key: Key('schedule-product-cron-${schedule.platform}-field'),
            controller: _productCronController(schedule),
            enabled: canConfigure,
            decoration: const InputDecoration(labelText: 'Cron Expression'),
          ),
          actions: [
            OutlinedButton.icon(
              key: Key('schedule-product-save-${schedule.platform}-button'),
              onPressed: canConfigure ? () => _saveProductCron(schedule) : null,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
            IconButton(
              key: Key('schedule-product-generate-${schedule.platform}-button'),
              tooltip: 'Generate cron',
              onPressed: canConfigure
                  ? () => _showCronGenerator(_productCronController(schedule))
                  : null,
              icon: const Icon(Icons.auto_awesome),
            ),
            IconButton(
              key: Key('schedule-product-delete-${schedule.platform}-button'),
              tooltip: 'Delete ${schedule.platform}',
              onPressed: canConfigure
                  ? () => _deleteProductSchedule(schedule)
                  : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobTimersTab(ScheduleSnapshot snapshot, bool canConfigure) {
    return _SchedulePanel(
      title: 'Job Crawl Schedule Config',
      child: MavraResponsiveDataView<JobSchedule>(
        key: const Key('schedule-job-table'),
        rows: snapshot.jobSchedules,
        wideBreakpoint: 760,
        empty: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text('No job search configs')),
        ),
        columns: const [
          DataColumn(label: Text('Config Name')),
          DataColumn(label: Text('Cron Expression')),
          DataColumn(label: Text('Next Run')),
          DataColumn(label: Text('Actions')),
        ],
        tableCells: (schedule) => [
          DataCell(Text(schedule.name)),
          DataCell(
            SizedBox(
              width: 160,
              child: TextField(
                key: Key('schedule-job-cron-${schedule.configId}-field'),
                controller: _jobCronController(schedule),
                enabled: canConfigure,
                decoration: MavraInputStyle.tableInput(context: context),
              ),
            ),
          ),
          DataCell(Text(_nextRunTableLabel(schedule.nextRunAt))),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  key: Key('schedule-job-save-${schedule.configId}-button'),
                  style: MavraButtonStyle.compactOutlined(context: context),
                  onPressed: canConfigure ? () => _saveJobCron(schedule) : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save'),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: Key('schedule-job-generate-${schedule.configId}-button'),
                  tooltip: 'Generate cron',
                  style: MavraButtonStyle.rowIconButton(context: context),
                  onPressed: canConfigure
                      ? () => _showCronGenerator(_jobCronController(schedule))
                      : null,
                  icon: const Icon(Icons.auto_awesome),
                ),
              ],
            ),
          ),
        ],
        mobileBuilder: (context, schedule) => _ScheduleTimerTile(
          title: schedule.name,
          subtitle: _cronLabel(schedule.cronExpression),
          nextRunAt: schedule.nextRunAt,
          icon: Icons.work_outline,
          cronField: TextField(
            key: Key('schedule-job-cron-${schedule.configId}-field'),
            controller: _jobCronController(schedule),
            enabled: canConfigure,
            decoration: const InputDecoration(labelText: 'Cron Expression'),
          ),
          actions: [
            OutlinedButton.icon(
              key: Key('schedule-job-save-${schedule.configId}-button'),
              onPressed: canConfigure ? () => _saveJobCron(schedule) : null,
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save'),
            ),
            IconButton(
              key: Key('schedule-job-generate-${schedule.configId}-button'),
              tooltip: 'Generate cron',
              onPressed: canConfigure
                  ? () => _showCronGenerator(_jobCronController(schedule))
                  : null,
              icon: const Icon(Icons.auto_awesome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(ScheduleSnapshot snapshot, bool canConfigure) {
    return _SchedulePanel(
      title: 'Data Retention & Notification Config',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.history),
                label: Text('${snapshot.settings.retentionDays} days'),
              ),
              if (snapshot.settings.feishuWebhookUrl != null &&
                  snapshot.settings.feishuWebhookUrl!.isNotEmpty)
                const Chip(
                  avatar: Icon(Icons.notifications_active),
                  label: Text('Webhook configured'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('schedule-retention-days-field'),
            controller: _retentionController,
            enabled: canConfigure,
            keyboardType: TextInputType.number,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Data Retention Days',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('schedule-webhook-url-field'),
            controller: _webhookController,
            enabled: canConfigure,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Feishu Webhook URL',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('schedule-save-settings-button'),
            style: MavraButtonStyle.compactFilled(context: context),
            onPressed: canConfigure ? _saveSettings : null,
            icon: const Icon(Icons.save, size: 18),
            label: const Text('Save settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.schedule, label: 'Schedule'),
          AdaptiveDestination(icon: Icons.work, label: 'Jobs'),
          AdaptiveDestination(icon: Icons.inventory_2, label: 'Products'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/jobs');
            case 3:
              context.go('/products');
            case 4:
              context.go('/analytics');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<ScheduleSnapshot>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('规则加载失败。'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('正在加载自动规则...'),
                      ],
                    ),
                  );
                }
                final current = _snapshot ?? const ScheduleSnapshot.empty();
                return _buildContent(current);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader();

  @override
  Widget build(BuildContext context) {
    return const MavraPageBanner(
      key: Key('schedule-title-banner'),
      accentColor: AppTheme.brandBlue700,
      eyebrow: 'Automation',
      title: 'Schedule Configuration',
      subtitle: 'Configure automated product and job timers',
    );
  }
}

class _ScheduleTabStrip extends StatelessWidget {
  const _ScheduleTabStrip({required this.activeTab, required this.onChanged});

  final _ScheduleWorkbenchTab activeTab;
  final ValueChanged<_ScheduleWorkbenchTab> onChanged;

  static const _tabs = [
    _ScheduleWorkbenchTab.productTimers,
    _ScheduleWorkbenchTab.jobTimers,
    _ScheduleWorkbenchTab.settings,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in _tabs)
          Builder(
            builder: (context) {
              final selected = activeTab == tab;
              return ChoiceChip(
                key: Key(tab.key),
                avatar: Icon(
                  tab.icon,
                  size: 16,
                  color: MavraTabChipStyle.iconColor(context, selected),
                ),
                label: Text(tab.label),
                labelStyle: MavraTabChipStyle.labelStyle(context, selected),
                selected: selected,
                selectedColor: MavraTabChipStyle.selectedColor(context),
                backgroundColor: MavraTabChipStyle.backgroundColor(context),
                side: MavraTabChipStyle.side(context),
                showCheckmark: false,
                onSelected: (_) => onChanged(tab),
              );
            },
          ),
      ],
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MavraTableStyle.panelDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ScheduleTimerTile extends StatelessWidget {
  const _ScheduleTimerTile({
    required this.title,
    required this.subtitle,
    required this.nextRunAt,
    required this.icon,
    required this.cronField,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final String? nextRunAt;
  final IconData icon;
  final Widget cronField;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon),
            title: Text(title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(subtitle),
                if (nextRunAt != null) Text('Next run $nextRunAt'),
              ],
            ),
          ),
          cronField,
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

String _platformLabel(String platform) => switch (platform) {
  'jd' => 'JD',
  'taobao' => 'Taobao',
  'amazon' => 'Amazon',
  _ => platform,
};

String _cronLabel(String cronExpression) {
  return cronExpression.trim().isEmpty ? 'Disabled' : cronExpression;
}

String _nextRunTableLabel(String? nextRunAt) {
  return nextRunAt ?? '-';
}
