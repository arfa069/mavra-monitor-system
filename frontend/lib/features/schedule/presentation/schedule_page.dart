import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../domain/schedule_models.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({
    super.key,
    required this.repository,
    this.permissions,
  });

  final ScheduleRepository repository;
  final Set<String>? permissions;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  Future<ScheduleSnapshot>? _scheduleFuture;
  ScheduleSnapshot? _snapshot;
  Object? _error;
  String? _statusMessage;
  String? _validationMessage;
  String? _previewExpression;
  bool _showForm = false;
  ScheduleRuleTarget _targetType = ScheduleRuleTarget.productPlatform;

  final _targetController = TextEditingController();
  final _hourController = TextEditingController(text: '9');
  final _minuteController = TextEditingController(text: '0');
  final _weekdaysController = TextEditingController(text: '*');
  final _retentionController = TextEditingController(text: '365');
  final _webhookController = TextEditingController();

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
      _load();
    }
  }

  @override
  void dispose() {
    _targetController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    _weekdaysController.dispose();
    _retentionController.dispose();
    _webhookController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _error = null;
      _scheduleFuture = Future.sync(widget.repository.loadSchedule)
        ..then((snapshot) {
          if (mounted) {
            setState(() {
              _snapshot = snapshot;
              _retentionController.text = '${snapshot.settings.retentionDays}';
              _webhookController.text =
                  snapshot.settings.feishuWebhookUrl ?? '';
            });
          }
        }).catchError((Object error) {
          if (mounted) {
            setState(() => _error = error);
          }
        });
    });
  }

  void _newRule() {
    setState(() {
      _showForm = true;
      _targetType = ScheduleRuleTarget.productPlatform;
      _targetController.clear();
      _hourController.text = '9';
      _minuteController.text = '0';
      _weekdaysController.text = '*';
      _validationMessage = null;
      _previewExpression = null;
    });
  }

  void _editProductSchedule(ProductSchedule schedule) {
    setState(() {
      _showForm = true;
      _targetType = ScheduleRuleTarget.productPlatform;
      _targetController.text = schedule.platform;
      _setCronFields(schedule.cronExpression);
      _validationMessage = null;
      _previewExpression = schedule.cronExpression;
    });
  }

  void _editJobSchedule(JobSchedule schedule) {
    setState(() {
      _showForm = true;
      _targetType = ScheduleRuleTarget.jobConfig;
      _targetController.text = '${schedule.configId}';
      _setCronFields(schedule.cronExpression);
      _validationMessage = null;
      _previewExpression = schedule.cronExpression;
    });
  }

  Future<void> _deleteProductSchedule(ProductSchedule schedule) async {
    try {
      await widget.repository.deleteProductCron(schedule.platform);
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = 'Deleted ${schedule.platform} schedule');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Delete failed: $error');
      }
    }
  }

  void _setCronFields(String expression) {
    final parts = expression.split(RegExp(r'\s+'));
    if (parts.length == 5) {
      _minuteController.text = parts[0];
      _hourController.text = parts[1];
      _weekdaysController.text = parts[4];
    }
  }

  Future<void> _previewCron() async {
    final draft = _draftFromForm();
    if (draft == null) {
      return;
    }
    try {
      final preview = await widget.repository.previewCron(draft);
      if (mounted) {
        setState(() {
          _previewExpression = preview.expression;
          _validationMessage = null;
        });
      }
    } on ScheduleValidationException catch (error) {
      if (mounted) {
        setState(() => _validationMessage = error.message);
      }
    }
  }

  Future<void> _saveRule() async {
    final draft = _draftFromForm();
    if (draft == null) {
      return;
    }
    try {
      await widget.repository.saveRule(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Saved ${draft.targetName}';
        _showForm = false;
        _validationMessage = null;
      });
      _load();
    } on ScheduleValidationException catch (error) {
      if (mounted) {
        setState(() => _validationMessage = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Save failed: $error');
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
        _statusMessage = 'Saved schedule settings';
        _validationMessage = null;
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Save failed: $error');
      }
    }
  }

  ScheduleRuleDraft? _draftFromForm() {
    final target = _targetController.text.trim();
    final hour = int.tryParse(_hourController.text.trim());
    final minute = int.tryParse(_minuteController.text.trim());
    if (hour == null) {
      setState(() => _validationMessage = 'Hour must be 0-23');
      return null;
    }
    if (minute == null) {
      setState(() => _validationMessage = 'Minute must be 0-59');
      return null;
    }

    final configId = _targetType == ScheduleRuleTarget.jobConfig
        ? int.tryParse(target)
        : null;
    final draft = ScheduleRuleDraft(
      targetType: _targetType,
      targetName: target,
      hour: hour,
      minute: minute,
      weekdays: _weekdaysController.text.trim(),
      configId: configId,
    );
    try {
      CronGenerator.validateDraft(draft);
      return draft;
    } on ScheduleValidationException catch (error) {
      setState(() => _validationMessage = error.message);
      return null;
    }
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
                return _ScheduleContent(
                  snapshot: current,
                  canConfigure: _canConfigure,
                  statusMessage: _statusMessage,
                  validationMessage: _validationMessage,
                  previewExpression: _previewExpression,
                  showForm: _showForm,
                  targetType: _targetType,
                  targetController: _targetController,
                  hourController: _hourController,
                  minuteController: _minuteController,
                  weekdaysController: _weekdaysController,
                  retentionController: _retentionController,
                  webhookController: _webhookController,
                  onNewRule: _canConfigure ? _newRule : null,
                  onTargetTypeChanged: (target) {
                    if (target == null) {
                      return;
                    }
                    setState(() => _targetType = target);
                  },
                  onPreviewCron: _previewCron,
                  onSaveRule: _saveRule,
                  onSaveSettings: _canConfigure ? _saveSettings : null,
                  onEditProductSchedule: _canConfigure
                      ? _editProductSchedule
                      : null,
                  onDeleteProductSchedule: _canConfigure
                      ? (schedule) {
                          _deleteProductSchedule(schedule);
                        }
                      : null,
                  onEditJobSchedule: _canConfigure ? _editJobSchedule : null,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ScheduleContent extends StatelessWidget {
  const _ScheduleContent({
    required this.snapshot,
    required this.canConfigure,
    required this.statusMessage,
    required this.validationMessage,
    required this.previewExpression,
    required this.showForm,
    required this.targetType,
    required this.targetController,
    required this.hourController,
    required this.minuteController,
    required this.weekdaysController,
    required this.retentionController,
    required this.webhookController,
    required this.onNewRule,
    required this.onTargetTypeChanged,
    required this.onPreviewCron,
    required this.onSaveRule,
    required this.onSaveSettings,
    required this.onEditProductSchedule,
    required this.onDeleteProductSchedule,
    required this.onEditJobSchedule,
  });

  final ScheduleSnapshot snapshot;
  final bool canConfigure;
  final String? statusMessage;
  final String? validationMessage;
  final String? previewExpression;
  final bool showForm;
  final ScheduleRuleTarget targetType;
  final TextEditingController targetController;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController weekdaysController;
  final TextEditingController retentionController;
  final TextEditingController webhookController;
  final VoidCallback? onNewRule;
  final ValueChanged<ScheduleRuleTarget?> onTargetTypeChanged;
  final Future<void> Function() onPreviewCron;
  final Future<void> Function() onSaveRule;
  final Future<void> Function()? onSaveSettings;
  final ValueChanged<ProductSchedule>? onEditProductSchedule;
  final ValueChanged<ProductSchedule>? onDeleteProductSchedule;
  final ValueChanged<JobSchedule>? onEditJobSchedule;

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
                  'Rules',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: onNewRule,
                icon: const Icon(Icons.add),
                label: const Text('New rule'),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          if (showForm) ...[
            const SizedBox(height: 12),
            _ScheduleRuleForm(
              targetType: targetType,
              targetController: targetController,
              hourController: hourController,
              minuteController: minuteController,
              weekdaysController: weekdaysController,
              validationMessage: validationMessage,
              previewExpression: previewExpression,
              onTargetTypeChanged: onTargetTypeChanged,
              onPreviewCron: onPreviewCron,
              onSaveRule: onSaveRule,
            ),
          ],
          const SizedBox(height: 16),
          _ScheduleSettingsForm(
            settings: snapshot.settings,
            retentionController: retentionController,
            webhookController: webhookController,
            onSaveSettings: onSaveSettings,
          ),
          const SizedBox(height: 16),
          if (!snapshot.hasRules)
            const Center(child: Text('还没有自动运行规则。'))
          else ...[
            _ScheduleSection(
              key: const Key('schedule-product-table'),
              title: 'Product schedules',
              child: _ProductScheduleTable(
                schedules: snapshot.productSchedules,
                onEdit: onEditProductSchedule,
                onDelete: onDeleteProductSchedule,
              ),
            ),
            _ScheduleSection(
              key: const Key('schedule-job-table'),
              title: 'Job schedules',
              child: _JobScheduleTable(
                schedules: snapshot.jobSchedules,
                onEdit: onEditJobSchedule,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScheduleRuleForm extends StatelessWidget {
  const _ScheduleRuleForm({
    required this.targetType,
    required this.targetController,
    required this.hourController,
    required this.minuteController,
    required this.weekdaysController,
    required this.validationMessage,
    required this.previewExpression,
    required this.onTargetTypeChanged,
    required this.onPreviewCron,
    required this.onSaveRule,
  });

  final ScheduleRuleTarget targetType;
  final TextEditingController targetController;
  final TextEditingController hourController;
  final TextEditingController minuteController;
  final TextEditingController weekdaysController;
  final String? validationMessage;
  final String? previewExpression;
  final ValueChanged<ScheduleRuleTarget?> onTargetTypeChanged;
  final Future<void> Function() onPreviewCron;
  final Future<void> Function() onSaveRule;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rule form', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<ScheduleRuleTarget>(
              initialValue: targetType,
              decoration: const InputDecoration(labelText: 'Target type'),
              items: const [
                DropdownMenuItem(
                  value: ScheduleRuleTarget.productPlatform,
                  child: Text('Product platform'),
                ),
                DropdownMenuItem(
                  value: ScheduleRuleTarget.jobConfig,
                  child: Text('Job config id'),
                ),
              ],
              onChanged: onTargetTypeChanged,
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('schedule-target-field'),
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Target'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('schedule-hour-field'),
                    controller: hourController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Hour'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: const Key('schedule-minute-field'),
                    controller: minuteController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Minute'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('schedule-weekdays-field'),
              controller: weekdaysController,
              decoration: const InputDecoration(labelText: 'Weekdays'),
            ),
            if (validationMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                validationMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (previewExpression != null) ...[
              const SizedBox(height: 8),
              Text(previewExpression!),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onPreviewCron,
                  icon: const Icon(Icons.preview),
                  label: const Text('预览 cron'),
                ),
                FilledButton.icon(
                  onPressed: onSaveRule,
                  icon: const Icon(Icons.save),
                  label: const Text('保存规则'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSettingsForm extends StatelessWidget {
  const _ScheduleSettingsForm({
    required this.settings,
    required this.retentionController,
    required this.webhookController,
    required this.onSaveSettings,
  });

  final ScheduleSettings settings;
  final TextEditingController retentionController;
  final TextEditingController webhookController;
  final Future<void> Function()? onSaveSettings;

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
              'Notification and retention',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.history),
                  label: Text('${settings.retentionDays} days'),
                ),
                if (settings.feishuWebhookUrl != null &&
                    settings.feishuWebhookUrl!.isNotEmpty)
                  const Chip(
                    avatar: Icon(Icons.notifications_active),
                    label: Text('Webhook configured'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('schedule-retention-days-field'),
              controller: retentionController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Retention days'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('schedule-webhook-url-field'),
              controller: webhookController,
              decoration: const InputDecoration(
                labelText: 'Feishu webhook URL',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('schedule-save-settings-button'),
              onPressed: onSaveSettings,
              icon: const Icon(Icons.save),
              label: const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _ProductScheduleTable extends StatelessWidget {
  const _ProductScheduleTable({
    required this.schedules,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ProductSchedule> schedules;
  final ValueChanged<ProductSchedule>? onEdit;
  final ValueChanged<ProductSchedule>? onDelete;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<ProductSchedule>(
      rows: schedules,
      wideBreakpoint: 900,
      columns: const [
        DataColumn(label: Text('Platform')),
        DataColumn(label: Text('Cron')),
        DataColumn(label: Text('Next run')),
        DataColumn(label: Text('Actions')),
      ],
      tableCells: (schedule) => [
        DataCell(Text(schedule.platform)),
        DataCell(Text(schedule.cronExpression)),
        DataCell(Text(_nextRunLabel(schedule.nextRunAt))),
        DataCell(
          Wrap(
            spacing: 4,
            children: [
              IconButton(
                key: Key('schedule-product-edit-${schedule.platform}-button'),
                tooltip: 'Edit ${schedule.platform}',
                onPressed: onEdit == null ? null : () => onEdit!(schedule),
                icon: const Icon(Icons.edit_calendar),
              ),
              IconButton(
                key: Key('schedule-product-delete-${schedule.platform}-button'),
                tooltip: 'Delete ${schedule.platform}',
                onPressed: onDelete == null ? null : () => onDelete!(schedule),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ],
      mobileBuilder: (context, schedule) => _ScheduleMobileTile(
        title: schedule.platform,
        subtitle: schedule.cronExpression,
        nextRunAt: schedule.nextRunAt,
        icon: Icons.inventory_2,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              key: Key('schedule-product-edit-${schedule.platform}-button'),
              tooltip: 'Edit ${schedule.platform}',
              onPressed: onEdit == null ? null : () => onEdit!(schedule),
              icon: const Icon(Icons.edit_calendar),
            ),
            IconButton(
              key: Key('schedule-product-delete-${schedule.platform}-button'),
              tooltip: 'Delete ${schedule.platform}',
              onPressed: onDelete == null ? null : () => onDelete!(schedule),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobScheduleTable extends StatelessWidget {
  const _JobScheduleTable({required this.schedules, required this.onEdit});

  final List<JobSchedule> schedules;
  final ValueChanged<JobSchedule>? onEdit;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<JobSchedule>(
      rows: schedules,
      wideBreakpoint: 900,
      columns: const [
        DataColumn(label: Text('Config')),
        DataColumn(label: Text('Cron')),
        DataColumn(label: Text('Next run')),
        DataColumn(label: Text('Actions')),
      ],
      tableCells: (schedule) => [
        DataCell(Text(schedule.name)),
        DataCell(Text(schedule.cronExpression)),
        DataCell(Text(_nextRunLabel(schedule.nextRunAt))),
        DataCell(
          IconButton(
            key: Key('schedule-job-edit-${schedule.configId}-button'),
            tooltip: 'Edit ${schedule.name}',
            onPressed: onEdit == null ? null : () => onEdit!(schedule),
            icon: const Icon(Icons.edit_calendar),
          ),
        ),
      ],
      mobileBuilder: (context, schedule) => _ScheduleMobileTile(
        title: schedule.name,
        subtitle: schedule.cronExpression,
        nextRunAt: schedule.nextRunAt,
        icon: Icons.work,
        trailing: IconButton(
          key: Key('schedule-job-edit-${schedule.configId}-button'),
          tooltip: 'Edit ${schedule.name}',
          onPressed: onEdit == null ? null : () => onEdit!(schedule),
          icon: const Icon(Icons.edit_calendar),
        ),
      ),
    );
  }
}

class _ScheduleMobileTile extends StatelessWidget {
  const _ScheduleMobileTile({
    required this.title,
    required this.subtitle,
    required this.nextRunAt,
    required this.icon,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String? nextRunAt;
  final IconData icon;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle),
            if (nextRunAt != null) Text('Next run $nextRunAt'),
          ],
        ),
        trailing: trailing,
      ),
    );
  }
}

String _nextRunLabel(String? nextRunAt) {
  return nextRunAt == null ? '-' : 'Next run $nextRunAt';
}
