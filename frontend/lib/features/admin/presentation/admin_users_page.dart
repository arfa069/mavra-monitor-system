import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/notifications/mavra_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
import '../domain/admin_models.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({
    super.key,
    required this.repository,
    this.currentUsername,
    this.permissions = const {
      'user:read',
      'user:manage',
      'user:delete',
      'rbac:read',
      'rbac:manage',
    },
  });

  final AdminRepository repository;
  final String? currentUsername;
  final Set<String> permissions;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  Future<AdminSnapshot>? _future;
  AdminSnapshot? _snapshot;
  Object? _error;
  int _page = 1;
  final _searchController = TextEditingController();
  String? _role;

  bool get _canRead => widget.permissions.contains('user:read');
  bool get _canManageUsers => widget.permissions.contains('user:manage');
  bool get _canDeleteUsers => widget.permissions.contains('user:delete');
  bool get _canReadRbac => widget.permissions.contains('rbac:read');
  bool get _canManageRbac => widget.permissions.contains('rbac:manage');

  @override
  void initState() {
    super.initState();
    if (_canRead) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant AdminUsersPage oldWidget) {
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
    super.dispose();
  }

  void _load() {
    final filter = AdminFilter(
      search: _emptyToNull(_searchController.text),
      role: _role,
      userPage: _page,
      includeRolePermissions: _canReadRbac,
    );
    setState(() {
      _error = null;
      _future = Future.sync(() => widget.repository.loadAdmin(filter))
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

  void _applyFilters() {
    setState(() => _page = 1);
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
        MavraNotifier.error(_friendlyActionError(error));
      }
    }
  }

  Future<void> _toggleUserActive(AdminUser user) async {
    try {
      final nextActive = !user.active;
      await widget.repository.setUserActive(user.id, nextActive);
      if (!mounted) {
        return;
      }
      final message = nextActive
          ? 'Enabled ${user.username}'
          : 'Disabled ${user.username}';
      MavraNotifier.success(message);
      setState(() {
        _snapshot = _snapshot == null
            ? null
            : AdminSnapshot(
                users: [
                  for (final item in _snapshot!.users)
                    if (item.id == user.id)
                      AdminUser(
                        id: item.id,
                        username: item.username,
                        email: item.email,
                        role: item.role,
                        active: nextActive,
                        createdAt: item.createdAt,
                      )
                    else
                      item,
                ],
                rolePermissions: _snapshot!.rolePermissions,
                auditLogs: _snapshot!.auditLogs,
                totalUsers: _snapshot!.totalUsers,
                totalAuditLogs: _snapshot!.totalAuditLogs,
                permissionsAvailable: _snapshot!.permissionsAvailable,
                realtime: _snapshot!.realtime,
                resourcePermissions: _snapshot!.resourcePermissions,
              );
      });
    } catch (error) {
      if (mounted) {
        MavraNotifier.error(_friendlyActionError(error));
      }
    }
  }

  Future<void> _showUserDialog([AdminUser? user]) async {
    final draft = await showDialog<AdminUserDraft>(
      context: context,
      builder: (context) => _UserEditorDialog(
        repository: widget.repository,
        user: user,
        canManageResourcePermissions: _canManageUsers,
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
      return const _PermissionDenied();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<AdminSnapshot>(
          future: _future,
          builder: (context, snapshot) {
            if (_error != null) {
              return const Center(child: Text('用户管理数据加载失败。'));
            }
            if (snapshot.connectionState != ConnectionState.done &&
                _snapshot == null) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('正在加载用户管理数据...'),
                  ],
                ),
              );
            }
            return _AdminUsersContent(
              snapshot: _snapshot ?? const AdminSnapshot.empty(),
              page: _page,
              searchController: _searchController,
              role: _role,
              canManageUsers: _canManageUsers,
              canDeleteUsers: _canDeleteUsers,
              canReadRbac: _canReadRbac,
              canManageRbac: _canManageRbac,
              currentUsername: widget.currentUsername,
              onRoleChanged: (role) => setState(() => _role = role),
              onApplyFilters: _applyFilters,
              onCreateUser: () => _showUserDialog(),
              onEditUser: _showUserDialog,
              onToggleUser: _toggleUserActive,
              onDeleteUser: (user) => _runAction(
                () => widget.repository.deleteUser(user.id),
                'Deleted ${user.username}',
              ),
              onPreviousPage: _page > 1
                  ? () {
                      setState(() => _page -= 1);
                      _load();
                    }
                  : null,
              onNextPage: (_snapshot?.totalUsers ?? 0) > _page * 20
                  ? () {
                      setState(() => _page += 1);
                      _load();
                    }
                  : null,
              onSaveRole: (role, permissions) => _runAction(
                () => widget.repository.updateRolePermissions(
                  role: role,
                  permissions: permissions,
                ),
                'Updated $role permissions',
              ),
            );
          },
        ),
      ),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _friendlyActionError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final detail = data['detail'] ?? data['message'];
        if (detail != null) {
          return 'Action failed: $detail';
        }
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        return 'Action failed: request was rejected ($statusCode).';
      }
    }
    return 'Action failed: $error';
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied();

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
            const Text('没有权限访问用户管理。'),
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

class _AdminUsersContent extends StatelessWidget {
  const _AdminUsersContent({
    required this.snapshot,
    required this.page,
    required this.searchController,
    required this.role,
    required this.canManageUsers,
    required this.canDeleteUsers,
    required this.canReadRbac,
    required this.canManageRbac,
    required this.currentUsername,
    required this.onRoleChanged,
    required this.onApplyFilters,
    required this.onCreateUser,
    required this.onEditUser,
    required this.onToggleUser,
    required this.onDeleteUser,
    required this.onPreviousPage,
    required this.onNextPage,
    required this.onSaveRole,
  });

  final AdminSnapshot snapshot;
  final int page;
  final TextEditingController searchController;
  final String? role;
  final bool canManageUsers;
  final bool canDeleteUsers;
  final bool canReadRbac;
  final bool canManageRbac;
  final String? currentUsername;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onCreateUser;
  final ValueChanged<AdminUser> onEditUser;
  final ValueChanged<AdminUser> onToggleUser;
  final ValueChanged<AdminUser> onDeleteUser;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;
  final void Function(String role, List<String> permissions) onSaveRole;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _UsersHeader(),
          const SizedBox(height: 12),
          _UsersToolbar(
            searchController: searchController,
            role: role,
            canManageUsers: canManageUsers,
            onRoleChanged: onRoleChanged,
            onApplyFilters: onApplyFilters,
            onCreateUser: onCreateUser,
          ),
          if (!snapshot.permissionsAvailable) ...[
            const SizedBox(height: 8),
            const Text('部分权限信息暂时不可用。'),
          ],
          const SizedBox(height: 12),
          if (snapshot.users.isEmpty)
            const Text('没有符合条件的用户。')
          else ...[
            _UsersTable(
              users: snapshot.users,
              canManageUsers: canManageUsers,
              canDeleteUsers: canDeleteUsers,
              canManageSuperAdmin: canManageRbac,
              currentUsername: currentUsername,
              onEditUser: onEditUser,
              onToggleUser: onToggleUser,
              onDeleteUser: onDeleteUser,
            ),
            _UsersPager(
              page: page,
              total: snapshot.totalUsers,
              onPrevious: onPreviousPage,
              onNext: onNextPage,
            ),
          ],
          if (canReadRbac && snapshot.rolePermissions.isNotEmpty) ...[
            const SizedBox(height: 20),
            _RolePermissionsMatrix(
              rolePermissions: snapshot.rolePermissions,
              canEdit: canManageRbac,
              onSaveRole: onSaveRole,
            ),
          ],
        ],
      ),
    );
  }
}

class _UsersHeader extends StatelessWidget {
  const _UsersHeader();

  @override
  Widget build(BuildContext context) {
    return const MavraPageBanner(
      key: Key('admin-users-title-banner'),
      accentColor: AppTheme.brandPurple,
      eyebrow: 'System Admin',
      title: 'User Management',
      subtitle: 'Manage user accounts, roles, and access permissions',
    );
  }
}

class _UsersToolbar extends StatelessWidget {
  const _UsersToolbar({
    required this.searchController,
    required this.role,
    required this.canManageUsers,
    required this.onRoleChanged,
    required this.onApplyFilters,
    required this.onCreateUser,
  });

  final TextEditingController searchController;
  final String? role;
  final bool canManageUsers;
  final ValueChanged<String?> onRoleChanged;
  final VoidCallback onApplyFilters;
  final VoidCallback onCreateUser;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          height: 40,
          child: TextField(
            key: const Key('admin-user-search-field'),
            controller: searchController,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Search username or email',
              suffixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (_) => onApplyFilters(),
          ),
        ),
        SizedBox(
          width: 210,
          height: 40,
          child: DropdownButtonFormField<String>(
            key: const Key('admin-role-filter'),
            initialValue: role,
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Role',
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(
                value: 'super_admin',
                child: Text('Super Admin'),
              ),
            ],
            onChanged: onRoleChanged,
          ),
        ),
        SizedBox(
          width: 150,
          height: 40,
          child: MavraFilterButton.filled(
            key: const Key('admin-apply-user-filters-button'),
            onPressed: onApplyFilters,
            icon: Icons.filter_alt,
            label: 'Apply filters',
          ),
        ),
        if (canManageUsers)
          SizedBox(
            width: 130,
            height: 40,
            child: MavraFilterButton.filled(
              key: const Key('admin-create-user-button'),
              onPressed: onCreateUser,
              icon: Icons.person_add,
              label: 'New User',
            ),
          ),
      ],
    );
  }
}

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.canManageUsers,
    required this.canDeleteUsers,
    required this.canManageSuperAdmin,
    required this.currentUsername,
    required this.onEditUser,
    required this.onToggleUser,
    required this.onDeleteUser,
  });

  final List<AdminUser> users;
  final bool canManageUsers;
  final bool canDeleteUsers;
  final bool canManageSuperAdmin;
  final String? currentUsername;
  final ValueChanged<AdminUser> onEditUser;
  final ValueChanged<AdminUser> onToggleUser;
  final ValueChanged<AdminUser> onDeleteUser;

  @override
  Widget build(BuildContext context) {
    final activeSuperAdminCount = users
        .where((user) => user.role == 'super_admin' && user.active)
        .length;

    return Container(
      decoration: MavraTableStyle.panelDecoration(context),
      padding: const EdgeInsets.all(16),
      child: MavraResponsiveDataView<AdminUser>(
        rows: users,
        wideBreakpoint: 900,
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Username')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Registered')),
          DataColumn(label: Text('Actions')),
        ],
        tableCells: (user) => [
          DataCell(Text('${user.id}')),
          DataCell(Text(user.username)),
          DataCell(Text(user.email)),
          DataCell(Text(_roleLabel(user.role))),
          DataCell(_StatusChip(active: user.active)),
          DataCell(Text(_dateLabel(user.createdAt))),
          DataCell(
            _UserActions(
              user: user,
              canManageUsers: canManageUsers,
              canDeleteUsers: canDeleteUsers,
              canManageSuperAdmin: canManageSuperAdmin,
              currentUsername: currentUsername,
              activeSuperAdminCount: activeSuperAdminCount,
              onEditUser: onEditUser,
              onToggleUser: onToggleUser,
              onDeleteUser: onDeleteUser,
            ),
          ),
        ],
        mobileBuilder: (context, user) => Container(
          decoration: MavraTableStyle.panelDecoration(context),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(user.email),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('#${user.id}'),
                  Text(_roleLabel(user.role)),
                  _StatusChip(active: user.active),
                  Text(_dateLabel(user.createdAt)),
                ],
              ),
              const SizedBox(height: 8),
              _UserActions(
                user: user,
                canManageUsers: canManageUsers,
                canDeleteUsers: canDeleteUsers,
                canManageSuperAdmin: canManageSuperAdmin,
                currentUsername: currentUsername,
                activeSuperAdminCount: activeSuperAdminCount,
                onEditUser: onEditUser,
                onToggleUser: onToggleUser,
                onDeleteUser: onDeleteUser,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(active ? 'Active' : 'Disabled'),
      side: BorderSide(color: active ? scheme.primary : scheme.error),
      backgroundColor: active
          ? scheme.primaryContainer.withValues(alpha: 0.25)
          : scheme.errorContainer.withValues(alpha: 0.25),
    );
  }
}

class _UserActions extends StatelessWidget {
  const _UserActions({
    required this.user,
    required this.canManageUsers,
    required this.canDeleteUsers,
    required this.canManageSuperAdmin,
    required this.currentUsername,
    required this.activeSuperAdminCount,
    required this.onEditUser,
    required this.onToggleUser,
    required this.onDeleteUser,
  });

  final AdminUser user;
  final bool canManageUsers;
  final bool canDeleteUsers;
  final bool canManageSuperAdmin;
  final String? currentUsername;
  final int activeSuperAdminCount;
  final ValueChanged<AdminUser> onEditUser;
  final ValueChanged<AdminUser> onToggleUser;
  final ValueChanged<AdminUser> onDeleteUser;

  bool get _canTouchRow => user.role != 'super_admin' || canManageSuperAdmin;
  bool get _isCurrentUser =>
      currentUsername != null && user.username == currentUsername;
  bool get _isLastActiveSuperAdmin =>
      user.role == 'super_admin' && user.active && activeSuperAdminCount <= 1;
  bool get _canToggleRow =>
      _canTouchRow && !_isCurrentUser && !_isLastActiveSuperAdmin;
  bool get _canDeleteRow =>
      _canTouchRow && !_isCurrentUser && !_isLastActiveSuperAdmin;

  String get _toggleTooltip {
    if (_isCurrentUser) {
      return 'Cannot disable your current account';
    }
    if (_isLastActiveSuperAdmin) {
      return 'Cannot disable the last active super admin';
    }
    return user.active ? 'Disable ${user.username}' : 'Enable ${user.username}';
  }

  String get _deleteTooltip {
    if (_isCurrentUser) {
      return 'Cannot delete your current account';
    }
    if (_isLastActiveSuperAdmin) {
      return 'Cannot delete the last active super admin';
    }
    return 'Delete ${user.username}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canManageUsers)
          IconButton(
            key: Key('admin-edit-user-${user.id}-button'),
            style: MavraButtonStyle.rowIconButton(context: context),
            tooltip: 'Edit ${user.username}',
            onPressed: _canTouchRow ? () => onEditUser(user) : null,
            icon: const Icon(Icons.edit_outlined),
          ),
        if (canManageUsers) ...[
          const SizedBox(width: 4),
          IconButton(
            key: Key('admin-toggle-user-${user.id}-button'),
            style: MavraButtonStyle.rowIconButton(context: context),
            tooltip: _toggleTooltip,
            onPressed: _canToggleRow ? () => onToggleUser(user) : null,
            icon: Icon(user.active ? Icons.block : Icons.check_circle_outline),
          ),
        ],
        if (canDeleteUsers) ...[
          const SizedBox(width: 4),
          IconButton(
            key: Key('admin-delete-user-${user.id}-button'),
            style: MavraButtonStyle.rowIconButton(
              context: context,
              isDangerous: true,
            ),
            tooltip: _deleteTooltip,
            onPressed: _canDeleteRow ? () => onDeleteUser(user) : null,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ],
    );
  }
}

class _UsersPager extends StatelessWidget {
  const _UsersPager({
    required this.page,
    required this.total,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int total;
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
          key: const Key('admin-users-previous-page-button'),
          tooltip: 'Previous page',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: const Key('admin-users-next-page-button'),
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _UserEditorDialog extends StatefulWidget {
  const _UserEditorDialog({
    required this.repository,
    required this.canManageResourcePermissions,
    this.user,
  });

  final AdminRepository repository;
  final AdminUser? user;
  final bool canManageResourcePermissions;

  @override
  State<_UserEditorDialog> createState() => _UserEditorDialogState();
}

class _UserEditorDialogState extends State<_UserEditorDialog> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late String _role;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final user = widget.user;
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _passwordController = TextEditingController();
    _role = user?.role ?? 'user';
    _active = user?.active ?? true;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.user != null;
    final mediaSize = MediaQuery.sizeOf(context);
    final dialogWidth = (editing ? 720.0 : 520.0).clamp(
      0,
      mediaSize.width - 48,
    );
    final dialogHeight = (mediaSize.height * 0.68).clamp(
      editing ? 360.0 : 300.0,
      editing ? 520.0 : 420.0,
    );
    return AlertDialog(
      title: Text(editing ? 'Edit User' : 'New User'),
      content: SizedBox(
        width: dialogWidth.toDouble(),
        height: dialogHeight.toDouble(),
        child: DefaultTabController(
          length: editing ? 2 : 1,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  const Tab(
                    key: Key('admin-user-basic-info-tab'),
                    text: 'Basic Info',
                  ),
                  if (editing)
                    const Tab(
                      key: Key('admin-user-resource-permissions-tab'),
                      text: 'Resource Permissions',
                    ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _basicInfoForm(editing),
                    if (editing)
                      _ResourcePermissionsEditor(
                        repository: widget.repository,
                        userId: widget.user!.id,
                        canManage: widget.canManageResourcePermissions,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          style: MavraButtonStyle.compactText(context: context),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('admin-save-user-button'),
          style: MavraButtonStyle.compactFilled(context: context),
          onPressed: () => Navigator.of(context).pop(
            AdminUserDraft(
              username: _usernameController.text.trim(),
              email: _emailController.text.trim(),
              role: _role,
              password: _emptyToNull(_passwordController.text),
              active: editing ? _active : null,
            ),
          ),
          child: Text(editing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Widget _basicInfoForm(bool editing) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          TextField(
            key: const Key('admin-user-username-field'),
            controller: _usernameController,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Username',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('admin-user-email-field'),
            controller: _emailController,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Email',
            ),
          ),
          const SizedBox(height: 12),
          if (!editing) ...[
            TextField(
              key: const Key('admin-user-password-field'),
              controller: _passwordController,
              obscureText: true,
              decoration: MavraInputStyle.filterInput(
                context: context,
                label: 'Password',
              ),
            ),
            const SizedBox(height: 12),
          ],
          DropdownButtonFormField<String>(
            key: const Key('admin-user-role-field'),
            initialValue: _role,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Role',
            ),
            items: const [
              DropdownMenuItem(value: 'user', child: Text('User')),
              DropdownMenuItem(value: 'admin', child: Text('Admin')),
              DropdownMenuItem(
                value: 'super_admin',
                child: Text('Super Admin'),
              ),
            ],
            onChanged: (value) => setState(() => _role = value ?? 'user'),
          ),
          if (editing) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              key: const Key('admin-user-active-switch'),
              title: const Text('Active'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
          ],
        ],
      ),
    );
  }

  static String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ResourcePermissionsEditor extends StatefulWidget {
  const _ResourcePermissionsEditor({
    required this.repository,
    required this.userId,
    required this.canManage,
  });

  final AdminRepository repository;
  final int userId;
  final bool canManage;

  @override
  State<_ResourcePermissionsEditor> createState() =>
      _ResourcePermissionsEditorState();
}

class _ResourcePermissionsEditorState
    extends State<_ResourcePermissionsEditor> {
  late Future<List<ResourcePermissionItem>> _future;
  int? _editingPermissionId;
  final _resourceIdController = TextEditingController();
  String _resourceType = 'product';
  String _permission = 'read';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _resourceIdController.dispose();
    super.dispose();
  }

  void _load() {
    _future = widget.repository.listResourcePermissions(userId: widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ResourcePermissionItem>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final permissions = snapshot.data ?? const [];
        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (permissions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('No resource permissions'),
                )
              else
                for (final permission in permissions)
                  _resourcePermissionRow(permission),
              if (widget.canManage) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('admin-grant-resource-button'),
                  style: MavraButtonStyle.compactOutlined(context: context),
                  onPressed: _showGrantDialog,
                  icon: const Icon(Icons.lock_open, size: 18),
                  label: const Text('Grant Permission'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _resourcePermissionRow(ResourcePermissionItem permission) {
    final editing = _editingPermissionId == permission.id;
    if (editing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: _resourceType,
                isExpanded: true,
                decoration: MavraInputStyle.filterInput(
                  context: context,
                  label: 'Type',
                ),
                items: _resourceTypeItems,
                onChanged: (value) {
                  setState(() => _resourceType = value ?? 'product');
                },
              ),
            ),
            SizedBox(
              width: 170,
              child: TextField(
                key: const Key('admin-resource-id-edit-field'),
                controller: _resourceIdController,
                decoration: MavraInputStyle.filterInput(
                  context: context,
                  label: 'Resource ID',
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                initialValue: _permission,
                isExpanded: true,
                decoration: MavraInputStyle.filterInput(
                  context: context,
                  label: 'Permission',
                ),
                items: _permissionItems,
                onChanged: (value) {
                  setState(() => _permission = value ?? 'read');
                },
              ),
            ),
            FilledButton(
              key: Key('admin-save-resource-${permission.id}-button'),
              style: MavraButtonStyle.compactFilled(context: context),
              onPressed: () async {
                await widget.repository.updateResourcePermission(
                  permission.id,
                  ResourcePermissionUpdateDraft(
                    resourceType: _resourceType,
                    resourceId: _resourceIdController.text.trim(),
                    permission: _permission,
                  ),
                );
                if (mounted) {
                  setState(() {
                    _editingPermissionId = null;
                    _load();
                  });
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(label: Text(permission.resourceType)),
          Chip(label: Text(permission.resourceId)),
          Chip(label: Text(permission.permission)),
          Text(_dateLabel(permission.createdAt)),
          if (widget.canManage)
            TextButton(
              key: Key('admin-edit-resource-${permission.id}-button'),
              style: MavraButtonStyle.compactText(context: context),
              onPressed: () {
                setState(() {
                  _editingPermissionId = permission.id;
                  _resourceType = permission.resourceType;
                  _permission = permission.permission;
                  _resourceIdController.text = permission.resourceId;
                });
              },
              child: const Text('Edit'),
            ),
          if (widget.canManage)
            TextButton(
              key: Key('admin-revoke-resource-${permission.id}-button'),
              style: MavraButtonStyle.compactText(
                context: context,
                isDangerous: true,
              ),
              onPressed: () async {
                await widget.repository.revokeResourcePermission(permission.id);
                if (mounted) {
                  setState(_load);
                }
              },
              child: const Text('Revoke'),
            ),
        ],
      ),
    );
  }

  Future<void> _showGrantDialog() async {
    final draft = await showDialog<ResourcePermissionGrantDraft>(
      context: context,
      builder: (context) => _GrantPermissionDialog(userId: widget.userId),
    );
    if (draft == null) {
      return;
    }
    await widget.repository.grantResourcePermissions(draft);
    if (mounted) {
      setState(_load);
    }
  }
}

class _GrantPermissionDialog extends StatefulWidget {
  const _GrantPermissionDialog({required this.userId});

  final int userId;

  @override
  State<_GrantPermissionDialog> createState() => _GrantPermissionDialogState();
}

class _GrantPermissionDialogState extends State<_GrantPermissionDialog> {
  final _resourceIdsController = TextEditingController();
  String _resourceType = 'product';
  String? _permission;

  @override
  void dispose() {
    _resourceIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Grant Resource Permission'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              key: const Key('admin-grant-resource-type-field'),
              initialValue: _resourceType,
              isExpanded: true,
              decoration: MavraInputStyle.filterInput(
                context: context,
                label: 'Resource Type',
              ),
              items: _resourceTypeItems,
              onChanged: (value) {
                setState(() => _resourceType = value ?? 'product');
              },
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('admin-grant-resource-ids-field'),
              controller: _resourceIdsController,
              decoration: MavraInputStyle.filterInput(
                context: context,
                label: 'Resource ID',
                helperText:
                    'Separate multiple resource IDs with commas, * for all',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              key: const Key('admin-grant-permission-field'),
              initialValue: _permission,
              isExpanded: true,
              decoration: MavraInputStyle.filterInput(
                context: context,
                label: 'Permission',
              ),
              items: const [
                DropdownMenuItem(value: 'read', child: Text('Read')),
                DropdownMenuItem(value: 'write', child: Text('Write')),
                DropdownMenuItem(value: 'delete', child: Text('Delete')),
                DropdownMenuItem(value: '*', child: Text('All (*)')),
              ],
              onChanged: (value) => setState(() => _permission = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: MavraButtonStyle.compactText(context: context),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('admin-confirm-grant-button'),
          style: MavraButtonStyle.compactFilled(context: context),
          onPressed: _permission == null
              ? null
              : () {
                  final resourceIds = _resourceIdsController.text
                      .split(',')
                      .map((value) => value.trim())
                      .where((value) => value.isNotEmpty)
                      .toList();
                  if (resourceIds.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(
                    ResourcePermissionGrantDraft(
                      subjectId: widget.userId,
                      resourceType: _resourceType,
                      resourceIds: resourceIds,
                      permission: _permission!,
                    ),
                  );
                },
          child: const Text('Confirm Grant'),
        ),
      ],
    );
  }
}

class _RolePermissionsMatrix extends StatefulWidget {
  const _RolePermissionsMatrix({
    required this.rolePermissions,
    required this.canEdit,
    required this.onSaveRole,
  });

  final List<AdminRolePermission> rolePermissions;
  final bool canEdit;
  final void Function(String role, List<String> permissions) onSaveRole;

  @override
  State<_RolePermissionsMatrix> createState() => _RolePermissionsMatrixState();
}

class _RolePermissionsMatrixState extends State<_RolePermissionsMatrix> {
  var _activeIndex = 0;
  late List<Set<String>> _drafts;
  late Map<String, Set<String>> _permissionCatalog;

  @override
  void initState() {
    super.initState();
    _drafts = _draftsFrom(widget.rolePermissions);
    _permissionCatalog = _catalogFrom(widget.rolePermissions);
  }

  @override
  void didUpdateWidget(covariant _RolePermissionsMatrix oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rolePermissions != widget.rolePermissions) {
      _drafts = _draftsFrom(widget.rolePermissions);
      _permissionCatalog = _mergeCatalog(
        _permissionCatalog,
        widget.rolePermissions,
      );
      _activeIndex = _activeIndex.clamp(0, widget.rolePermissions.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rolePermissions.isEmpty) {
      return const SizedBox.shrink();
    }
    final activeRole = widget.rolePermissions[_activeIndex];
    return Container(
      decoration: MavraTableStyle.panelDecoration(context),
      padding: const EdgeInsets.all(16),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role Permissions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            DefaultTabController(
              length: widget.rolePermissions.length,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    onTap: (index) => setState(() => _activeIndex = index),
                    tabs: [
                      for (final role in widget.rolePermissions)
                        Tab(
                          key: Key('admin-role-tab-${role.role}'),
                          text: _roleLabel(role.role),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _RolePermissionGroup(
                    role: activeRole,
                    availablePermissions:
                        _permissionCatalog[activeRole.role] ??
                        activeRole.permissions.toSet(),
                    permissions: _drafts[_activeIndex],
                    canEdit: widget.canEdit,
                    onChanged: (permission, checked) {
                      if (!widget.canEdit) {
                        return;
                      }
                      setState(() {
                        if (checked) {
                          _drafts[_activeIndex].add(permission);
                        } else {
                          _drafts[_activeIndex].remove(permission);
                        }
                      });
                    },
                  ),
                  if (widget.canEdit) ...[
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('admin-save-role-permissions-button'),
                      style: MavraButtonStyle.compactFilled(context: context),
                      onPressed: () => widget.onSaveRole(
                        activeRole.role,
                        _drafts[_activeIndex].toList(),
                      ),
                      child: const Text('Save'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<Set<String>> _draftsFrom(List<AdminRolePermission> roles) {
    return [for (final role in roles) role.permissions.toSet()];
  }

  static Map<String, Set<String>> _catalogFrom(
    List<AdminRolePermission> roles,
  ) {
    return {
      for (final role in roles)
        role.role:
            (role.availablePermissions.isEmpty
                    ? role.permissions
                    : role.availablePermissions)
                .toSet(),
    };
  }

  static Map<String, Set<String>> _mergeCatalog(
    Map<String, Set<String>> previous,
    List<AdminRolePermission> roles,
  ) {
    final next = {
      for (final entry in previous.entries) entry.key: {...entry.value},
    };
    for (final role in roles) {
      final permissions = role.availablePermissions.isEmpty
          ? role.permissions
          : role.availablePermissions;
      next.putIfAbsent(role.role, () => <String>{}).addAll(permissions);
    }
    return next;
  }
}

class _RolePermissionGroup extends StatelessWidget {
  const _RolePermissionGroup({
    required this.role,
    required this.availablePermissions,
    required this.permissions,
    required this.canEdit,
    required this.onChanged,
  });

  final AdminRolePermission role;
  final Set<String> availablePermissions;
  final Set<String> permissions;
  final bool canEdit;
  final void Function(String permission, bool checked) onChanged;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<String>>{};
    for (final permission in availablePermissions.toList()..sort()) {
      final group = permission.split(':').first;
      grouped.putIfAbsent(group, () => []).add(permission);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final groupWidth = constraints.maxWidth < 560
            ? constraints.maxWidth
            : 176.0;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final entry in grouped.entries)
              SizedBox(
                width: groupWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key),
                    for (final permission in entry.value)
                      CheckboxListTile(
                        key: Key(
                          'admin-role-${role.role}-${_permissionKey(permission)}',
                        ),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Tooltip(
                          message: permission,
                          child: Text(
                            permission,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        value: permissions.contains(permission),
                        onChanged: canEdit
                            ? (checked) =>
                                  onChanged(permission, checked == true)
                            : null,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

String _permissionKey(String permission) => permission.replaceAll(':', '-');

const _resourceTypeItems = [
  DropdownMenuItem(value: 'product', child: Text('Product')),
  DropdownMenuItem(value: 'job', child: Text('Job')),
  DropdownMenuItem(value: 'user', child: Text('User')),
];

const _permissionItems = [
  DropdownMenuItem(value: 'read', child: Text('Read')),
  DropdownMenuItem(value: 'write', child: Text('Write')),
  DropdownMenuItem(value: 'delete', child: Text('Delete')),
  DropdownMenuItem(value: '*', child: Text('All (*)')),
];

// Button styles are defined in MavraButtonStyle

String _roleLabel(String role) {
  return switch (role) {
    'super_admin' => 'Super Admin',
    'admin' => 'Admin',
    'user' => 'User',
    _ => role,
  };
}

String _dateLabel(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
