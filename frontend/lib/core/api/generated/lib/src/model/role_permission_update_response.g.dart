// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_permission_update_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RolePermissionUpdateResponse extends RolePermissionUpdateResponse {
  @override
  final BuiltList<String> permissions;
  @override
  final String role;

  factory _$RolePermissionUpdateResponse(
          [void Function(RolePermissionUpdateResponseBuilder)? updates]) =>
      (RolePermissionUpdateResponseBuilder()..update(updates))._build();

  _$RolePermissionUpdateResponse._(
      {required this.permissions, required this.role})
      : super._();
  @override
  RolePermissionUpdateResponse rebuild(
          void Function(RolePermissionUpdateResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RolePermissionUpdateResponseBuilder toBuilder() =>
      RolePermissionUpdateResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RolePermissionUpdateResponse &&
        permissions == other.permissions &&
        role == other.role;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permissions.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RolePermissionUpdateResponse')
          ..add('permissions', permissions)
          ..add('role', role))
        .toString();
  }
}

class RolePermissionUpdateResponseBuilder
    implements
        Builder<RolePermissionUpdateResponse,
            RolePermissionUpdateResponseBuilder> {
  _$RolePermissionUpdateResponse? _$v;

  ListBuilder<String>? _permissions;
  ListBuilder<String> get permissions =>
      _$this._permissions ??= ListBuilder<String>();
  set permissions(ListBuilder<String>? permissions) =>
      _$this._permissions = permissions;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  RolePermissionUpdateResponseBuilder() {
    RolePermissionUpdateResponse._defaults(this);
  }

  RolePermissionUpdateResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permissions = $v.permissions.toBuilder();
      _role = $v.role;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RolePermissionUpdateResponse other) {
    _$v = other as _$RolePermissionUpdateResponse;
  }

  @override
  void update(void Function(RolePermissionUpdateResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RolePermissionUpdateResponse build() => _build();

  _$RolePermissionUpdateResponse _build() {
    _$RolePermissionUpdateResponse _$result;
    try {
      _$result = _$v ??
          _$RolePermissionUpdateResponse._(
            permissions: permissions.build(),
            role: BuiltValueNullFieldError.checkNotNull(
                role, r'RolePermissionUpdateResponse', 'role'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissions';
        permissions.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RolePermissionUpdateResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
