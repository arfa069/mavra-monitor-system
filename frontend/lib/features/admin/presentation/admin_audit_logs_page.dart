import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
import '../domain/admin_models.dart';

class AdminAuditLogsPage extends StatefulWidget {
  const AdminAuditLogsPage({
    super.key,
    required this.repository,
    this.permissions = const {'user:read'},
  });

  final AdminRepository repository;
  final Set<String> permissions;

  @override
  State<AdminAuditLogsPage> createState() => _AdminAuditLogsPageState();
}

class _AdminAuditLogsPageState extends State<AdminAuditLogsPage> {
  AuditLogPageState? _pageState;
  Object? _error;
  bool _loading = false;
  int _page = 1;
  int _pageSize = 20;

  bool get _canReadAuditLogs => widget.permissions.contains('user:read');

  @override
  void initState() {
    super.initState();
    if (_canReadAuditLogs) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant AdminAuditLogsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.permissions != widget.permissions) {
      _pageState = null;
      _error = null;
      _page = 1;
      if (_canReadAuditLogs) {
        _load();
      }
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pageState = await widget.repository.listAuditLogs(
        AdminFilter(
          auditPage: _page,
          pageSize: _pageSize,
          includeRolePermissions: false,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _pageState = pageState;
        _page = pageState.page;
        _pageSize = pageState.pageSize;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _goToPage(int page) {
    setState(() => _page = page);
    _load();
  }

  void _changePageSize(int pageSize) {
    setState(() {
      _page = 1;
      _pageSize = pageSize;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canReadAuditLogs) {
      return const _AuditPermissionDenied();
    }
    final pageState =
        _pageState ??
        AuditLogPageState(
          items: const [],
          page: _page,
          pageSize: _pageSize,
          total: 0,
        );
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _AuditHeader(),
              const SizedBox(height: 12),
              if (_error != null)
                const Center(child: Text('审计日志加载失败。'))
              else if (_loading && _pageState == null)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('正在加载审计日志...'),
                    ],
                  ),
                )
              else if (pageState.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('没有审计日志。'),
                )
              else ...[
                _AuditLogTable(logs: pageState.items),
                const SizedBox(height: 12),
                _AuditPager(
                  page: pageState.page,
                  pageSize: pageState.pageSize,
                  total: pageState.total,
                  loading: _loading,
                  onPrevious: pageState.page > 1
                      ? () => _goToPage(pageState.page - 1)
                      : null,
                  onNext: pageState.total > pageState.page * pageState.pageSize
                      ? () => _goToPage(pageState.page + 1)
                      : null,
                  onPageSizeChanged: _changePageSize,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AuditPermissionDenied extends StatelessWidget {
  const _AuditPermissionDenied();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 44),
            const SizedBox(height: 16),
            const Text('没有权限访问审计日志。'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.go('/today'),
              icon: const Icon(Icons.today),
              label: const Text('回到 Today'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditHeader extends StatelessWidget {
  const _AuditHeader();

  @override
  Widget build(BuildContext context) {
    return const MavraPageBanner(
      key: Key('admin-audit-logs-title-banner'),
      accentColor: AppTheme.brandCoral,
      eyebrow: 'System Admin',
      title: 'Audit Logs',
      subtitle: 'View system operation audit records',
    );
  }
}

class _AuditLogTable extends StatelessWidget {
  const _AuditLogTable({required this.logs});

  final List<AdminAuditLog> logs;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: MavraTableStyle.panelDecoration(context),
      padding: const EdgeInsets.all(16),
      child: MavraResponsiveDataView<AdminAuditLog>(
        rows: logs,
        wideBreakpoint: 720,
        columnSpacing: 24,
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Action')),
          DataColumn(label: Text('Actor ID')),
          DataColumn(label: Text('Target Type')),
          DataColumn(label: Text('Target ID')),
          DataColumn(label: Text('Details')),
          DataColumn(label: Text('IP Address')),
          DataColumn(label: Text('Time')),
        ],
        tableCells: (log) => [
          DataCell(Text('${log.id}')),
          DataCell(_ActionChip(log: log)),
          DataCell(Text(_actorLabel(log.actorUserId))),
          DataCell(Text(log.targetType ?? '-')),
          DataCell(Text(log.targetId?.toString() ?? '-')),
          DataCell(_DetailsText(details: log.details)),
          DataCell(Text(log.ipAddress ?? '-')),
          DataCell(Text(_dateLabel(log.createdAt))),
        ],
        mobileBuilder: (context, log) => Container(
          decoration: MavraTableStyle.panelDecoration(context),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('#${log.id}'),
                  const SizedBox(width: 8),
                  _ActionChip(log: log),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  Text('Actor ${_actorLabel(log.actorUserId)}'),
                  Text('Target ${log.targetType ?? '-'}'),
                  Text('ID ${log.targetId?.toString() ?? '-'}'),
                  Text(log.ipAddress ?? '-'),
                  Text(_dateLabel(log.createdAt)),
                ],
              ),
              if (log.details != null) ...[
                const SizedBox(height: 8),
                _DetailsText(details: log.details),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.log});

  final AdminAuditLog log;

  @override
  Widget build(BuildContext context) {
    final color = _actionColor(context, log.action);
    return Chip(
      key: Key('admin-audit-action-chip-${log.id}'),
      label: Text(_actionLabel(log.action)),
      side: BorderSide(color: color),
      backgroundColor: color.withValues(alpha: 0.16),
    );
  }
}

class _DetailsText extends StatelessWidget {
  const _DetailsText({required this.details});

  final Map<String, Object?>? details;

  @override
  Widget build(BuildContext context) {
    if (details == null || details!.isEmpty) {
      return const Text('-');
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Text(
        const JsonEncoder.withIndent('  ').convert(details),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }
}

class _AuditPager extends StatelessWidget {
  const _AuditPager({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.loading,
    required this.onPrevious,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final bool loading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Total $total records'),
        Text('Page $page'),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<int>(
            key: const Key('admin-audit-page-size-field'),
            initialValue: pageSize,
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Rows',
            ),
            items: const [
              DropdownMenuItem(value: 20, child: Text('20 / page')),
              DropdownMenuItem(value: 50, child: Text('50 / page')),
              DropdownMenuItem(value: 100, child: Text('100 / page')),
            ],
            onChanged: loading || total == 0
                ? null
                : (value) {
                    if (value != null) {
                      onPageSizeChanged(value);
                    }
                  },
          ),
        ),
        IconButton(
          key: const Key('admin-audits-previous-page-button'),
          tooltip: 'Previous page',
          onPressed: loading ? null : onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: const Key('admin-audits-next-page-button'),
          tooltip: 'Next page',
          onPressed: loading ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

String _actorLabel(int? actorUserId) {
  return actorUserId == null ? '-' : '$actorUserId';
}

String _dateLabel(DateTime value) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)} '
      '${two(value.hour)}:${two(value.minute)}';
}

String _actionLabel(String action) => _actionLabels[action] ?? action;

Color _actionColor(BuildContext context, String action) {
  final scheme = Theme.of(context).colorScheme;
  switch (_actionColors[action]) {
    case 'green':
      return AppTheme.successText;
    case 'blue':
      return AppTheme.focusBlue;
    case 'red':
      return scheme.error;
    case 'cyan':
      return AppTheme.home;
    case 'orange':
      return AppTheme.warning;
    default:
      return scheme.outline;
  }
}

const _actionLabels = {
  'user.create': 'Create User',
  'user.update': 'Update User',
  'user.delete': 'Delete User',
  'user.register': 'User Register',
  'user.password_change': 'Change Password',
  'user.wechat_bind': 'Bind WeChat',
  'auth.login': 'User Login',
  'auth.logout': 'User Logout',
  'product.update': 'Update Product',
  'product.delete': 'Delete Product',
  'schedule.create': 'Create Schedule',
  'schedule.update': 'Update Schedule',
  'schedule.delete': 'Delete Schedule',
  'job_config.create': 'Create Job Config',
  'job_config.update': 'Update Job Config',
  'job_config.delete': 'Delete Job Config',
};

const _actionColors = {
  'user.create': 'green',
  'user.update': 'blue',
  'user.delete': 'red',
  'user.register': 'cyan',
  'user.password_change': 'orange',
  'user.wechat_bind': 'cyan',
  'auth.login': 'green',
  'auth.logout': 'default',
  'product.update': 'blue',
  'product.delete': 'red',
  'schedule.create': 'green',
  'schedule.update': 'blue',
  'schedule.delete': 'red',
  'job_config.create': 'green',
  'job_config.update': 'blue',
  'job_config.delete': 'red',
};
