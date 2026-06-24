// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_permission_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RolePermissionResponse extends RolePermissionResponse {
  @override
  final BuiltList<String> permissions;
  @override
  final String role;
  @override
  final String? description;

  factory _$RolePermissionResponse([
    void Function(RolePermissionResponseBuilder)? updates,
  ]) => (RolePermissionResponseBuilder()..update(updates))._build();

  _$RolePermissionResponse._({
    required this.permissions,
    required this.role,
    this.description,
  }) : super._();
  @override
  RolePermissionResponse rebuild(
    void Function(RolePermissionResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  RolePermissionResponseBuilder toBuilder() =>
      RolePermissionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RolePermissionResponse &&
        permissions == other.permissions &&
        role == other.role &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permissions.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RolePermissionResponse')
          ..add('permissions', permissions)
          ..add('role', role)
          ..add('description', description))
        .toString();
  }
}

class RolePermissionResponseBuilder
    implements Builder<RolePermissionResponse, RolePermissionResponseBuilder> {
  _$RolePermissionResponse? _$v;

  ListBuilder<String>? _permissions;
  ListBuilder<String> get permissions =>
      _$this._permissions ??= ListBuilder<String>();
  set permissions(ListBuilder<String>? permissions) =>
      _$this._permissions = permissions;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  RolePermissionResponseBuilder() {
    RolePermissionResponse._defaults(this);
  }

  RolePermissionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permissions = $v.permissions.toBuilder();
      _role = $v.role;
      _description = $v.description;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RolePermissionResponse other) {
    _$v = other as _$RolePermissionResponse;
  }

  @override
  void update(void Function(RolePermissionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RolePermissionResponse build() => _build();

  _$RolePermissionResponse _build() {
    _$RolePermissionResponse _$result;
    try {
      _$result =
          _$v ??
          _$RolePermissionResponse._(
            permissions: permissions.build(),
            role: BuiltValueNullFieldError.checkNotNull(
              role,
              r'RolePermissionResponse',
              'role',
            ),
            description: description,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissions';
        permissions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'RolePermissionResponse',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
