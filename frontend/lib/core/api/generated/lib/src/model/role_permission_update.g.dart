// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'role_permission_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RolePermissionUpdate extends RolePermissionUpdate {
  @override
  final BuiltList<String>? permissions;

  factory _$RolePermissionUpdate(
          [void Function(RolePermissionUpdateBuilder)? updates]) =>
      (RolePermissionUpdateBuilder()..update(updates))._build();

  _$RolePermissionUpdate._({this.permissions}) : super._();
  @override
  RolePermissionUpdate rebuild(
          void Function(RolePermissionUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RolePermissionUpdateBuilder toBuilder() =>
      RolePermissionUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RolePermissionUpdate && permissions == other.permissions;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permissions.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RolePermissionUpdate')
          ..add('permissions', permissions))
        .toString();
  }
}

class RolePermissionUpdateBuilder
    implements Builder<RolePermissionUpdate, RolePermissionUpdateBuilder> {
  _$RolePermissionUpdate? _$v;

  ListBuilder<String>? _permissions;
  ListBuilder<String> get permissions =>
      _$this._permissions ??= ListBuilder<String>();
  set permissions(ListBuilder<String>? permissions) =>
      _$this._permissions = permissions;

  RolePermissionUpdateBuilder() {
    RolePermissionUpdate._defaults(this);
  }

  RolePermissionUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permissions = $v.permissions?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RolePermissionUpdate other) {
    _$v = other as _$RolePermissionUpdate;
  }

  @override
  void update(void Function(RolePermissionUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RolePermissionUpdate build() => _build();

  _$RolePermissionUpdate _build() {
    _$RolePermissionUpdate _$result;
    try {
      _$result = _$v ??
          _$RolePermissionUpdate._(
            permissions: _permissions?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'permissions';
        _permissions?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RolePermissionUpdate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
