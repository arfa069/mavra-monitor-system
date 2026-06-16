// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AuditLogResponse extends AuditLogResponse {
  @override
  final String action;
  @override
  final int? actorUserId;
  @override
  final DateTime createdAt;
  @override
  final BuiltMap<String, JsonObject?>? details;
  @override
  final int id;
  @override
  final String? ipAddress;
  @override
  final int? targetId;
  @override
  final String? targetType;
  @override
  final String? userAgent;

  factory _$AuditLogResponse([
    void Function(AuditLogResponseBuilder)? updates,
  ]) => (AuditLogResponseBuilder()..update(updates))._build();

  _$AuditLogResponse._({
    required this.action,
    this.actorUserId,
    required this.createdAt,
    this.details,
    required this.id,
    this.ipAddress,
    this.targetId,
    this.targetType,
    this.userAgent,
  }) : super._();
  @override
  AuditLogResponse rebuild(void Function(AuditLogResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AuditLogResponseBuilder toBuilder() =>
      AuditLogResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AuditLogResponse &&
        action == other.action &&
        actorUserId == other.actorUserId &&
        createdAt == other.createdAt &&
        details == other.details &&
        id == other.id &&
        ipAddress == other.ipAddress &&
        targetId == other.targetId &&
        targetType == other.targetType &&
        userAgent == other.userAgent;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, actorUserId.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, details.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, ipAddress.hashCode);
    _$hash = $jc(_$hash, targetId.hashCode);
    _$hash = $jc(_$hash, targetType.hashCode);
    _$hash = $jc(_$hash, userAgent.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AuditLogResponse')
          ..add('action', action)
          ..add('actorUserId', actorUserId)
          ..add('createdAt', createdAt)
          ..add('details', details)
          ..add('id', id)
          ..add('ipAddress', ipAddress)
          ..add('targetId', targetId)
          ..add('targetType', targetType)
          ..add('userAgent', userAgent))
        .toString();
  }
}

class AuditLogResponseBuilder
    implements Builder<AuditLogResponse, AuditLogResponseBuilder> {
  _$AuditLogResponse? _$v;

  String? _action;
  String? get action => _$this._action;
  set action(String? action) => _$this._action = action;

  int? _actorUserId;
  int? get actorUserId => _$this._actorUserId;
  set actorUserId(int? actorUserId) => _$this._actorUserId = actorUserId;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  MapBuilder<String, JsonObject?>? _details;
  MapBuilder<String, JsonObject?> get details =>
      _$this._details ??= MapBuilder<String, JsonObject?>();
  set details(MapBuilder<String, JsonObject?>? details) =>
      _$this._details = details;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _ipAddress;
  String? get ipAddress => _$this._ipAddress;
  set ipAddress(String? ipAddress) => _$this._ipAddress = ipAddress;

  int? _targetId;
  int? get targetId => _$this._targetId;
  set targetId(int? targetId) => _$this._targetId = targetId;

  String? _targetType;
  String? get targetType => _$this._targetType;
  set targetType(String? targetType) => _$this._targetType = targetType;

  String? _userAgent;
  String? get userAgent => _$this._userAgent;
  set userAgent(String? userAgent) => _$this._userAgent = userAgent;

  AuditLogResponseBuilder() {
    AuditLogResponse._defaults(this);
  }

  AuditLogResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _action = $v.action;
      _actorUserId = $v.actorUserId;
      _createdAt = $v.createdAt;
      _details = $v.details?.toBuilder();
      _id = $v.id;
      _ipAddress = $v.ipAddress;
      _targetId = $v.targetId;
      _targetType = $v.targetType;
      _userAgent = $v.userAgent;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AuditLogResponse other) {
    _$v = other as _$AuditLogResponse;
  }

  @override
  void update(void Function(AuditLogResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AuditLogResponse build() => _build();

  _$AuditLogResponse _build() {
    _$AuditLogResponse _$result;
    try {
      _$result =
          _$v ??
          _$AuditLogResponse._(
            action: BuiltValueNullFieldError.checkNotNull(
              action,
              r'AuditLogResponse',
              'action',
            ),
            actorUserId: actorUserId,
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'AuditLogResponse',
              'createdAt',
            ),
            details: _details?.build(),
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'AuditLogResponse',
              'id',
            ),
            ipAddress: ipAddress,
            targetId: targetId,
            targetType: targetType,
            userAgent: userAgent,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'details';
        _details?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'AuditLogResponse',
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
