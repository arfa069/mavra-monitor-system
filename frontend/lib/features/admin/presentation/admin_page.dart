import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/mavra_notifier.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
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
  int _loadRequestId = 0;
  int _userPage = 1;
  int _auditPage = 1;
  final _searchController = TextEditingController();
  final _roleController = TextEditingController();
  final _auditActionController = TextEditingController();
  final _auditActorController = TextEditingController();

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
    _roleController.dispose();
    _auditActionController.dispose();
    _auditActorController.dispose();
    super.dispose();
  }

  void _load() {
    final requestId = ++_loadRequestId;
    final filter = AdminFilter(
      search: _emptyToNull(_searchController.text),
      role: _emptyToNull(_roleController.text),
      auditAction: _emptyToNull(_auditActionController.text),
      auditActorUserId: int.tryParse(_auditActorController.text.trim()),
      userPage: _userPage,
      auditPage: _auditPage,
      includeRolePermissions: _canReadRbac,
    );
    final future = Future.sync(() => widget.repository.loadAdmin(filter));
    setState(() {
      _error = null;
      _adminFuture = future;
    });
    future
        .then((snapshot) {
          if (mounted && requestId == _loadRequestId) {
            setState(() => _snapshot = snapshot);
          }
        })
        .catchError((Object error) {
          if (mounted && requestId == _loadRequestId) {
            setState(() => _error = error);
          }
        });
  }

  void _applyFilters() {
    setState(() {
      _userPage = 1;
      _auditPage = 1;
    });
    _load();
  }

  void _goToUserPage(int page) {
    setState(() => _userPage = page);
    _load();
  }

  void _goToAuditPage(int page) {
    setState(() => _auditPage = page);
    _load();
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      MavraNotifier.success(successMessage);
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Action failed: $error');
      }
    }
  }

  Future<void> _showUserDialog([AdminUser? user]) async {
    final usernameController = TextEditingController(
      text: user?.username ?? '',
    );
    final emailController = TextEditingController(text: user?.email ?? '');
    final roleController = TextEditingController(text: user?.role ?? 'user');
    final passwordController = TextEditingController();
    final draft = await showDialog<AdminUserDraft>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user == null ? 'Create user' : 'Edit ${user.username}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('admin-user-username-field'),
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('admin-user-email-field'),
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('admin-user-role-field'),
                controller: roleController,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const Key('admin-user-password-field'),
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('admin-save-user-button'),
            onPressed: () => Navigator.of(context).pop(
              AdminUserDraft(
                username: usernameController.text.trim(),
                email: emailController.text.trim(),
                role: roleController.text.trim(),
                password: _emptyToNull(passwordController.text),
                active: user?.active,
              ),
            ),
            child: const Text('Save user'),
          ),
        ],
      ),
    );
    if (draft == null) {
      return;
    }
    if (user == null) {
      await _runAction(
        () => widget.repository.createUser(draft),
        'Created user',
      );
      return;
    }
    await _runAction(
      () => widget.repository.updateUser(user.id, draft),
      'Updated ${user.username}',
    );
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
                  roleController: _roleController,
                  auditActionController: _auditActionController,
                  auditActorController: _auditActorController,
                  userPage: _userPage,
                  auditPage: _auditPage,
                  onApplyFilters: _applyFilters,
                  onCreateUser: _showUserDialog,
                  onEditUser: _showUserDialog,
                  onToggleUser: (user) => _runAction(
                    () =>
                        widget.repository.setUserActive(user.id, !user.active),
                    user.active
                        ? 'Disabled ${user.username}'
                        : 'Enabled ${user.username}',
                  ),
                  onDeleteUser: (user) => _runAction(
                    () => widget.repository.deleteUser(user.id),
                    'Deleted ${user.username}',
                  ),
                  onPreviousUsers: _userPage > 1
                      ? () => _goToUserPage(_userPage - 1)
                      : null,
                  onNextUsers: (_snapshot?.totalUsers ?? 0) > _userPage * 20
                      ? () => _goToUserPage(_userPage + 1)
                      : null,
                  onPreviousAudits: _auditPage > 1
                      ? () => _goToAuditPage(_auditPage - 1)
                      : null,
                  onNextAudits:
                      (_snapshot?.totalAuditLogs ?? 0) > _auditPage * 20
                      ? () => _goToAuditPage(_auditPage + 1)
                      : null,
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
    required this.roleController,
    required this.auditActionController,
    required this.auditActorController,
    required this.userPage,
    required this.auditPage,
    required this.onApplyFilters,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onToggleUser,
    required this.onDeleteUser,
    required this.onPreviousUsers,
    required this.onNextUsers,
    required this.onPreviousAudits,
    required this.onNextAudits,
  });

  final AdminSnapshot snapshot;
  final bool canManageUsers;
  final bool canReadRbac;
  final TextEditingController searchController;
  final TextEditingController roleController;
  final TextEditingController auditActionController;
  final TextEditingController auditActorController;
  final int userPage;
  final int auditPage;
  final VoidCallback onApplyFilters;
  final VoidCallback onCreateUser;
  final ValueChanged<AdminUser> onEditUser;
  final ValueChanged<AdminUser> onToggleUser;
  final ValueChanged<AdminUser> onDeleteUser;
  final VoidCallback? onPreviousUsers;
  final VoidCallback? onNextUsers;
  final VoidCallback? onPreviousAudits;
  final VoidCallback? onNextAudits;

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
            children: const [
              ActionChip(
                key: Key('admin-users-tab'),
                avatar: Icon(Icons.people, size: 16),
                label: Text('User list'),
                onPressed: null,
              ),
              ActionChip(
                key: Key('admin-audit-logs-tab'),
                avatar: Icon(Icons.receipt_long, size: 16),
                label: Text('Audit trail'),
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (canManageUsers)
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                key: const Key('admin-create-user-button'),
                onPressed: onCreateUser,
                icon: const Icon(Icons.person_add),
                label: const Text('Create user'),
              ),
            ),
          if (canManageUsers) const SizedBox(height: 8),
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
                width: 160,
                child: TextField(
                  key: const Key('admin-role-field'),
                  controller: roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
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
              SizedBox(
                width: 160,
                child: TextField(
                  key: const Key('admin-audit-actor-field'),
                  controller: auditActorController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Actor id'),
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
            _UserTable(
              users: snapshot.users,
              canManageUsers: canManageUsers,
              onEditUser: onEditUser,
              onToggleUser: onToggleUser,
              onDeleteUser: onDeleteUser,
            ),
            _AdminPager(
              page: userPage,
              total: snapshot.totalUsers,
              previousKey: const Key('admin-users-previous-page-button'),
              nextKey: const Key('admin-users-next-page-button'),
              onPrevious: onPreviousUsers,
              onNext: onNextUsers,
            ),
            if (canReadRbac) ...[
              const SizedBox(height: 20),
              _PermissionMatrix(rolePermissions: snapshot.rolePermissions),
            ],
            const SizedBox(height: 20),
            _AuditLogList(logs: snapshot.auditLogs),
            _AdminPager(
              page: auditPage,
              total: snapshot.totalAuditLogs,
              previousKey: const Key('admin-audits-previous-page-button'),
              nextKey: const Key('admin-audits-next-page-button'),
              onPrevious: onPreviousAudits,
              onNext: onNextAudits,
            ),
          ],
        ],
      ),
    );
  }
}

class _UserTable extends StatelessWidget {
  const _UserTable({
    required this.users,
    required this.canManageUsers,
    required this.onEditUser,
    required this.onToggleUser,
    required this.onDeleteUser,
  });

  final List<AdminUser> users;
  final bool canManageUsers;
  final ValueChanged<AdminUser> onEditUser;
  final ValueChanged<AdminUser> onToggleUser;
  final ValueChanged<AdminUser> onDeleteUser;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }
    return MavraResponsiveDataView<AdminUser>(
      rows: users,
      wideBreakpoint: 900,
      columns: const [
        DataColumn(label: Text('Action')),
        DataColumn(label: Text('User')),
        DataColumn(label: Text('Email')),
        DataColumn(label: Text('Role')),
        DataColumn(label: Text('Status')),
      ],
      tableCells: (user) => [
        DataCell(
          _UserActions(
            user: user,
            canManageUsers: canManageUsers,
            onEditUser: onEditUser,
            onToggleUser: onToggleUser,
            onDeleteUser: onDeleteUser,
          ),
        ),
        DataCell(Text(user.username)),
        DataCell(Text(user.email)),
        DataCell(Text(user.role)),
        DataCell(Text(user.active ? 'active' : 'inactive')),
      ],
      mobileBuilder: (context, user) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.person),
          title: Text(user.username),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.email),
              Text(user.role),
              Text(user.active ? 'active' : 'inactive'),
            ],
          ),
          trailing: _UserActions(
            user: user,
            canManageUsers: canManageUsers,
            onEditUser: onEditUser,
            onToggleUser: onToggleUser,
            onDeleteUser: onDeleteUser,
          ),
        ),
      ),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.user,
    required this.canManageUsers,
    required this.onEditUser,
    required this.onToggleUser,
    required this.onDeleteUser,
  });

  final AdminUser user;
  final bool canManageUsers;
  final ValueChanged<AdminUser> onEditUser;
  final ValueChanged<AdminUser> onToggleUser;
  final ValueChanged<AdminUser> onDeleteUser;

  @override
  Widget build(BuildContext context) {
    if (!canManageUsers) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 4,
      children: [
        TextButton(
          key: Key('admin-edit-user-${user.id}-button'),
          onPressed: () => onEditUser(user),
          child: Text('Manage ${user.username}'),
        ),
        IconButton(
          key: Key('admin-toggle-user-${user.id}-button'),
          tooltip: user.active
              ? 'Disable ${user.username}'
              : 'Enable ${user.username}',
          onPressed: () => onToggleUser(user),
          icon: Icon(user.active ? Icons.block : Icons.check_circle_outline),
        ),
        IconButton(
          key: Key('admin-delete-user-${user.id}-button'),
          tooltip: 'Delete ${user.username}',
          onPressed: () => onDeleteUser(user),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    );
  }
}

class _AdminPager extends StatelessWidget {
  const _AdminPager({
    required this.page,
    required this.total,
    required this.previousKey,
    required this.nextKey,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int total;
  final Key previousKey;
  final Key nextKey;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (total <= 20 && page <= 1) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Text('Page $page'),
        const Spacer(),
        IconButton(
          key: previousKey,
          tooltip: 'Previous page',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: nextKey,
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
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
        MavraResponsiveDataView<AdminAuditLog>(
          rows: logs,
          wideBreakpoint: 900,
          columns: const [
            DataColumn(label: Text('Action')),
            DataColumn(label: Text('Actor')),
            DataColumn(label: Text('Target')),
            DataColumn(label: Text('Date')),
          ],
          tableCells: (log) => [
            DataCell(
              KeyedSubtree(
                key: Key('admin-audit-row-${log.id}'),
                child: Text(log.action),
              ),
            ),
            DataCell(
              Text(log.actorUserId == null ? '-' : 'actor #${log.actorUserId}'),
            ),
            DataCell(Text(log.targetType ?? '-')),
            DataCell(Text(_shortDate(log.createdAt))),
          ],
          mobileBuilder: (context, log) => ListTile(
            key: Key('admin-audit-row-${log.id}'),
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
        ),
      ],
    );
  }

  static String _shortDate(DateTime value) {
    return '${value.year}-${value.month}-${value.day}';
  }
}
