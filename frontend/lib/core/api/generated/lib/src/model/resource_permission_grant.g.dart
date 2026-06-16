// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_permission_grant.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResourcePermissionGrant extends ResourcePermissionGrant {
  @override
  final String permission;
  @override
  final BuiltList<String> resourceIds;
  @override
  final String resourceType;
  @override
  final int subjectId;

  factory _$ResourcePermissionGrant([
    void Function(ResourcePermissionGrantBuilder)? updates,
  ]) => (ResourcePermissionGrantBuilder()..update(updates))._build();

  _$ResourcePermissionGrant._({
    required this.permission,
    required this.resourceIds,
    required this.resourceType,
    required this.subjectId,
  }) : super._();
  @override
  ResourcePermissionGrant rebuild(
    void Function(ResourcePermissionGrantBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ResourcePermissionGrantBuilder toBuilder() =>
      ResourcePermissionGrantBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResourcePermissionGrant &&
        permission == other.permission &&
        resourceIds == other.resourceIds &&
        resourceType == other.resourceType &&
        subjectId == other.subjectId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, resourceIds.hashCode);
    _$hash = $jc(_$hash, resourceType.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResourcePermissionGrant')
          ..add('permission', permission)
          ..add('resourceIds', resourceIds)
          ..add('resourceType', resourceType)
          ..add('subjectId', subjectId))
        .toString();
  }
}

class ResourcePermissionGrantBuilder
    implements
        Builder<ResourcePermissionGrant, ResourcePermissionGrantBuilder> {
  _$ResourcePermissionGrant? _$v;

  String? _permission;
  String? get permission => _$this._permission;
  set permission(String? permission) => _$this._permission = permission;

  ListBuilder<String>? _resourceIds;
  ListBuilder<String> get resourceIds =>
      _$this._resourceIds ??= ListBuilder<String>();
  set resourceIds(ListBuilder<String>? resourceIds) =>
      _$this._resourceIds = resourceIds;

  String? _resourceType;
  String? get resourceType => _$this._resourceType;
  set resourceType(String? resourceType) => _$this._resourceType = resourceType;

  int? _subjectId;
  int? get subjectId => _$this._subjectId;
  set subjectId(int? subjectId) => _$this._subjectId = subjectId;

  ResourcePermissionGrantBuilder() {
    ResourcePermissionGrant._defaults(this);
  }

  ResourcePermissionGrantBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _permission = $v.permission;
      _resourceIds = $v.resourceIds.toBuilder();
      _resourceType = $v.resourceType;
      _subjectId = $v.subjectId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResourcePermissionGrant other) {
    _$v = other as _$ResourcePermissionGrant;
  }

  @override
  void update(void Function(ResourcePermissionGrantBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResourcePermissionGrant build() => _build();

  _$ResourcePermissionGrant _build() {
    _$ResourcePermissionGrant _$result;
    try {
      _$result =
          _$v ??
          _$ResourcePermissionGrant._(
            permission: BuiltValueNullFieldError.checkNotNull(
              permission,
              r'ResourcePermissionGrant',
              'permission',
            ),
            resourceIds: resourceIds.build(),
            resourceType: BuiltValueNullFieldError.checkNotNull(
              resourceType,
              r'ResourcePermissionGrant',
              'resourceType',
            ),
            subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId,
              r'ResourcePermissionGrant',
              'subjectId',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'resourceIds';
        resourceIds.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ResourcePermissionGrant',
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
