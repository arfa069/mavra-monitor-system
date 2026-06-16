// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_permission_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResourcePermissionUpdate extends ResourcePermissionUpdate {
  @override
  final String? permission;
  @override
  final String? resourceId;
  @override
  final String? resourceType;

  factory _$ResourcePermissionUpdate(
          [void Function(ResourcePermissionUpdateBuilder)? updates]) =>
      (ResourcePermissionUpdateBuilder()..update(updates))._build();

  _$ResourcePermissionUpdate._(
      {this.permission, this.resourceId, this.resourceType})
      : super._();
  @override
  ResourcePermissionUpdate rebuild(
          void Function(ResourcePermissionUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResourcePermissionUpdateBuilder toBuilder() =>
      ResourcePermissionUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResourcePermissionUpdate &&
        permission == other.permission &&
        resourceId == other.resourceId &&
        resourceType == other.resourceType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, resourceId.hashCode);
    _$hash = $jc(_$hash, resourceType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResourcePermissionUpdate')
          ..add('permission', permission)
          ..add('resourceId', resourceId)
          ..add('resourceType', resourceType))
        .toString();
  }
}

class ResourcePermissionUpdateBuilder
    implements
        Builder<ResourcePermissionUpdate, ResourcePermissionUpdateBuilder> {
  _$ResourcePermissionUpdate? _$v;

  String? _permission;
  String? get permission => _$this._permission;
  set permission(String? permission) => _$this._permission = permission;

  String? _resourceId;
  String? get resourceId => _$this._resourceId;
  set resourceId(String? resourceId) => _$this._resourceId = resourceId;

  String? _resourceType;
  String? get resourceType => _$this._resourceType;
  set resourceType(String? resourceType) => _$this._resourceType = resourceType;

  ResourcePermissionUpdateBuilder() {
    ResourcePermissionUpdate._defaults(this);
  }

  ResourcePermissionUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permission = $v.permission;
      _resourceId = $v.resourceId;
      _resourceType = $v.resourceType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResourcePermissionUpdate other) {
    _$v = other as _$ResourcePermissionUpdate;
  }

  @override
  void update(void Function(ResourcePermissionUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResourcePermissionUpdate build() => _build();

  _$ResourcePermissionUpdate _build() {
    final _$result = _$v ??
        _$ResourcePermissionUpdate._(
          permission: permission,
          resourceId: resourceId,
          resourceType: resourceType,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
