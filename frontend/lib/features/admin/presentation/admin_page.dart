import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/adaptive_scaffold.dart';
import '../domain/admin_models.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({
    super.key,
    required this.repository,
    this.permissions = const {
      'user:read',
      'user:manage',
      'rbac:read',
      'rbac:manage',
    },
  });

  final AdminRepository repository;
  final Set<String> permissions;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  Future<AdminSnapshot>? _adminFuture;
  AdminSnapshot? _snapshot;
  Object? _error;
  final _searchController = TextEditingController();
  final _auditActionController = TextEditingController();

  bool get _canRead => widget.permissions.contains('user:read');

  bool get _canReadRbac => widget.permissions.contains('rbac:read');

  bool get _canManageUsers => widget.permissions.contains('user:manage');

  @override
  void initState() {
    super.initState();
    if (_canRead) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant AdminPage oldWidget) {
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
    _searchController.dispose();
    _auditActionController.dispose();
    super.dispose();
  }

  void _load() {
    final filter = AdminFilter(
      search: _emptyToNull(_searchController.text),
      auditAction: _emptyToNull(_auditActionController.text),
      includeRolePermissions: _canReadRbac,
    );
    setState(() {
      _error = null;
      _adminFuture = Future.sync(() => widget.repository.loadAdmin(filter))
        ..then((snapshot) {
          if (mounted) {
            setState(() => _snapshot = snapshot);
          }
        }).catchError((Object error) {
          if (mounted) {
            setState(() => _error = error);
          }
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRead) {
      return const _AdminPermissionDenied();
    }

    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.people, label: 'Admin'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
          AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/analytics');
            case 3:
              context.go('/settings');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<AdminSnapshot>(
              future: _adminFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('管理数据加载失败。'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('正在加载管理数据...'),
                      ],
                    ),
                  );
                }
                return _AdminContent(
                  snapshot: _snapshot ?? const AdminSnapshot.empty(),
                  canManageUsers: _canManageUsers,
                  canReadRbac: _canReadRbac,
                  searchController: _searchController,
                  auditActionController: _auditActionController,
                  onApplyFilters: _load,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _AdminPermissionDenied extends StatelessWidget {
  const _AdminPermissionDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 44),
              const SizedBox(height: 16),
              const Text('没有权限访问管理功能。'),
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

class _AdminContent extends StatelessWidget {
  const _AdminContent({
    required this.snapshot,
    required this.canManageUsers,
    required this.canReadRbac,
    required this.searchController,
    required this.auditActionController,
    required this.onApplyFilters,
  });

  final AdminSnapshot snapshot;
  final bool canManageUsers;
  final bool canReadRbac;
  final TextEditingController searchController;
  final TextEditingController auditActionController;
  final VoidCallback onApplyFilters;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Users', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('admin-user-search-field'),
                  controller: searchController,
                  decoration: const InputDecoration(labelText: 'Search users'),
                ),
              ),
              SizedBox(
                width: 220,
                child: TextField(
                  key: const Key('admin-audit-action-field'),
                  controller: auditActionController,
                  decoration: const InputDecoration(labelText: 'Audit action'),
                ),
              ),
              FilledButton.icon(
                onPressed: onApplyFilters,
                icon: const Icon(Icons.filter_alt),
                label: const Text('Apply filters'),
              ),
            ],
          ),
          if (!snapshot.realtime) ...[
            const SizedBox(height: 8),
            const Text('管理数据不是实时状态。'),
          ],
          if (!snapshot.permissionsAvailable) ...[
            const SizedBox(height: 8),
            const Text('部分权限信息暂时不可用。'),
          ],
          const SizedBox(height: 12),
          if (snapshot.isEmpty)
            const Text('没有符合条件的记录。')
          else ...[
            _UserTable(users: snapshot.users, canManageUsers: canManageUsers),
            if (canReadRbac) ...[
              const SizedBox(height: 20),
              _PermissionMatrix(rolePermissions: snapshot.rolePermissions),
            ],
            const SizedBox(height: 20),
            _AuditLogList(logs: snapshot.auditLogs),
          ],
        ],
      ),
    );
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({required this.users, required this.canManageUsers});

  final List<AdminUser> users;
  final bool canManageUsers;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('User')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Action')),
        ],
        rows: [
          for (final user in users)
            DataRow(
              cells: [
                DataCell(Text(user.username)),
                DataCell(Text(user.email)),
                DataCell(Text(user.role)),
                DataCell(Text(user.active ? 'active' : 'inactive')),
                DataCell(
                  canManageUsers
                      ? TextButton(
                          onPressed: () {},
                          child: Text('Manage ${user.username}'),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PermissionMatrix extends StatelessWidget {
  const _PermissionMatrix({required this.rolePermissions});

  final List<AdminRolePermission> rolePermissions;

  @override
  Widget build(BuildContext context) {
    if (rolePermissions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Permission matrix',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final role in rolePermissions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, right: 8),
                  child: Icon(Icons.admin_panel_settings),
                ),
                SizedBox(width: 120, child: Text(role.role)),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final permission in role.permissions)
                        Chip(label: Text(permission)),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AuditLogList extends StatelessWidget {
  const _AuditLogList({required this.logs});

  final List<AdminAuditLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audit Logs', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final log in logs)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long),
            title: Text(log.action),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (log.actorUserId != null) Text('actor #${log.actorUserId}'),
                if (log.targetType != null) Text(log.targetType!),
                Text(_shortDate(log.createdAt)),
              ],
            ),
          ),
      ],
    );
  }

  static String _shortDate(DateTime value) {
    return '${value.year}-${value.month}-${value.day}';
  }
}
