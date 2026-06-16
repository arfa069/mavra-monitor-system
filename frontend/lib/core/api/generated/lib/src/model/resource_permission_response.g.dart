// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resource_permission_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResourcePermissionResponse extends ResourcePermissionResponse {
  @override
  final DateTime createdAt;
  @override
  final int grantedBy;
  @override
  final int id;
  @override
  final String permission;
  @override
  final String resourceId;
  @override
  final String resourceType;
  @override
  final int subjectId;
  @override
  final String subjectType;

  factory _$ResourcePermissionResponse(
          [void Function(ResourcePermissionResponseBuilder)? updates]) =>
      (ResourcePermissionResponseBuilder()..update(updates))._build();

  _$ResourcePermissionResponse._(
      {required this.createdAt,
      required this.grantedBy,
      required this.id,
      required this.permission,
      required this.resourceId,
      required this.resourceType,
      required this.subjectId,
      required this.subjectType})
      : super._();
  @override
  ResourcePermissionResponse rebuild(
          void Function(ResourcePermissionResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResourcePermissionResponseBuilder toBuilder() =>
      ResourcePermissionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResourcePermissionResponse &&
        createdAt == other.createdAt &&
        grantedBy == other.grantedBy &&
        id == other.id &&
        permission == other.permission &&
        resourceId == other.resourceId &&
        resourceType == other.resourceType &&
        subjectId == other.subjectId &&
        subjectType == other.subjectType;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, grantedBy.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, permission.hashCode);
    _$hash = $jc(_$hash, resourceId.hashCode);
    _$hash = $jc(_$hash, resourceType.hashCode);
    _$hash = $jc(_$hash, subjectId.hashCode);
    _$hash = $jc(_$hash, subjectType.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResourcePermissionResponse')
          ..add('createdAt', createdAt)
          ..add('grantedBy', grantedBy)
          ..add('id', id)
          ..add('permission', permission)
          ..add('resourceId', resourceId)
          ..add('resourceType', resourceType)
          ..add('subjectId', subjectId)
          ..add('subjectType', subjectType))
        .toString();
  }
}

class ResourcePermissionResponseBuilder
    implements
        Builder<ResourcePermissionResponse, ResourcePermissionResponseBuilder> {
  _$ResourcePermissionResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _grantedBy;
  int? get grantedBy => _$this._grantedBy;
  set grantedBy(int? grantedBy) => _$this._grantedBy = grantedBy;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _permission;
  String? get permission => _$this._permission;
  set permission(String? permission) => _$this._permission = permission;

  String? _resourceId;
  String? get resourceId => _$this._resourceId;
  set resourceId(String? resourceId) => _$this._resourceId = resourceId;

  String? _resourceType;
  String? get resourceType => _$this._resourceType;
  set resourceType(String? resourceType) => _$this._resourceType = resourceType;

  int? _subjectId;
  int? get subjectId => _$this._subjectId;
  set subjectId(int? subjectId) => _$this._subjectId = subjectId;

  String? _subjectType;
  String? get subjectType => _$this._subjectType;
  set subjectType(String? subjectType) => _$this._subjectType = subjectType;

  ResourcePermissionResponseBuilder() {
    ResourcePermissionResponse._defaults(this);
  }

  ResourcePermissionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _grantedBy = $v.grantedBy;
      _id = $v.id;
      _permission = $v.permission;
      _resourceId = $v.resourceId;
      _resourceType = $v.resourceType;
      _subjectId = $v.subjectId;
      _subjectType = $v.subjectType;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResourcePermissionResponse other) {
    _$v = other as _$ResourcePermissionResponse;
  }

  @override
  void update(void Function(ResourcePermissionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResourcePermissionResponse build() => _build();

  _$ResourcePermissionResponse _build() {
    final _$result = _$v ??
        _$ResourcePermissionResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'ResourcePermissionResponse', 'createdAt'),
          grantedBy: BuiltValueNullFieldError.checkNotNull(
              grantedBy, r'ResourcePermissionResponse', 'grantedBy'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ResourcePermissionResponse', 'id'),
          permission: BuiltValueNullFieldError.checkNotNull(
              permission, r'ResourcePermissionResponse', 'permission'),
          resourceId: BuiltValueNullFieldError.checkNotNull(
              resourceId, r'ResourcePermissionResponse', 'resourceId'),
          resourceType: BuiltValueNullFieldError.checkNotNull(
              resourceType, r'ResourcePermissionResponse', 'resourceType'),
          subjectId: BuiltValueNullFieldError.checkNotNull(
              subjectId, r'ResourcePermissionResponse', 'subjectId'),
          subjectType: BuiltValueNullFieldError.checkNotNull(
              subjectType, r'ResourcePermissionResponse', 'subjectType'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
