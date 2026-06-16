// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_permission_matrix_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RolePermissionMatrixResponse extends RolePermissionMatrixResponse {
  @override
  final BuiltList<PermissionResponse> allPermissions;
  @override
  final BuiltList<RolePermissionResponse> roles;

  factory _$RolePermissionMatrixResponse(
          [void Function(RolePermissionMatrixResponseBuilder)? updates]) =>
      (RolePermissionMatrixResponseBuilder()..update(updates))._build();

  _$RolePermissionMatrixResponse._(
      {required this.allPermissions, required this.roles})
      : super._();
  @override
  RolePermissionMatrixResponse rebuild(
          void Function(RolePermissionMatrixResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RolePermissionMatrixResponseBuilder toBuilder() =>
      RolePermissionMatrixResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RolePermissionMatrixResponse &&
        allPermissions == other.allPermissions &&
        roles == other.roles;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, allPermissions.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RolePermissionMatrixResponse')
          ..add('allPermissions', allPermissions)
          ..add('roles', roles))
        .toString();
  }
}

class RolePermissionMatrixResponseBuilder
    implements
        Builder<RolePermissionMatrixResponse,
            RolePermissionMatrixResponseBuilder> {
  _$RolePermissionMatrixResponse? _$v;

  ListBuilder<PermissionResponse>? _allPermissions;
  ListBuilder<PermissionResponse> get allPermissions =>
      _$this._allPermissions ??= ListBuilder<PermissionResponse>();
  set allPermissions(ListBuilder<PermissionResponse>? allPermissions) =>
      _$this._allPermissions = allPermissions;

  ListBuilder<RolePermissionResponse>? _roles;
  ListBuilder<RolePermissionResponse> get roles =>
      _$this._roles ??= ListBuilder<RolePermissionResponse>();
  set roles(ListBuilder<RolePermissionResponse>? roles) =>
      _$this._roles = roles;

  RolePermissionMatrixResponseBuilder() {
    RolePermissionMatrixResponse._defaults(this);
  }

  RolePermissionMatrixResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _allPermissions = $v.allPermissions.toBuilder();
      _roles = $v.roles.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RolePermissionMatrixResponse other) {
    _$v = other as _$RolePermissionMatrixResponse;
  }

  @override
  void update(void Function(RolePermissionMatrixResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RolePermissionMatrixResponse build() => _build();

  _$RolePermissionMatrixResponse _build() {
    _$RolePermissionMatrixResponse _$result;
    try {
      _$result = _$v ??
          _$RolePermissionMatrixResponse._(
            allPermissions: allPermissions.build(),
            roles: roles.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'allPermissions';
        allPermissions.build();
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RolePermissionMatrixResponse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
