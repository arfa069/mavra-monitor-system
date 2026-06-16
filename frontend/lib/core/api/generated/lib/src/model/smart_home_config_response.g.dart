// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_config_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeConfigResponse extends SmartHomeConfigResponse {
  @override
  final String baseUrl;
  @override
  final DateTime createdAt;
  @override
  final bool enabled;
  @override
  final int id;
  @override
  final DateTime updatedAt;
  @override
  final String? lastError;
  @override
  final String? lastStatus;
  @override
  final bool? tokenConfigured;

  factory _$SmartHomeConfigResponse([
    void Function(SmartHomeConfigResponseBuilder)? updates,
  ]) => (SmartHomeConfigResponseBuilder()..update(updates))._build();

  _$SmartHomeConfigResponse._({
    required this.baseUrl,
    required this.createdAt,
    required this.enabled,
    required this.id,
    required this.updatedAt,
    this.lastError,
    this.lastStatus,
    this.tokenConfigured,
  }) : super._();
  @override
  SmartHomeConfigResponse rebuild(
    void Function(SmartHomeConfigResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SmartHomeConfigResponseBuilder toBuilder() =>
      SmartHomeConfigResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeConfigResponse &&
        baseUrl == other.baseUrl &&
        createdAt == other.createdAt &&
        enabled == other.enabled &&
        id == other.id &&
        updatedAt == other.updatedAt &&
        lastError == other.lastError &&
        lastStatus == other.lastStatus &&
        tokenConfigured == other.tokenConfigured;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, baseUrl.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, lastError.hashCode);
    _$hash = $jc(_$hash, lastStatus.hashCode);
    _$hash = $jc(_$hash, tokenConfigured.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeConfigResponse')
          ..add('baseUrl', baseUrl)
          ..add('createdAt', createdAt)
          ..add('enabled', enabled)
          ..add('id', id)
          ..add('updatedAt', updatedAt)
          ..add('lastError', lastError)
          ..add('lastStatus', lastStatus)
          ..add('tokenConfigured', tokenConfigured))
        .toString();
  }
}

class SmartHomeConfigResponseBuilder
    implements
        Builder<SmartHomeConfigResponse, SmartHomeConfigResponseBuilder> {
  _$SmartHomeConfigResponse? _$v;

  String? _baseUrl;
  String? get baseUrl => _$this._baseUrl;
  set baseUrl(String? baseUrl) => _$this._baseUrl = baseUrl;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _lastError;
  String? get lastError => _$this._lastError;
  set lastError(String? lastError) => _$this._lastError = lastError;

  String? _lastStatus;
  String? get lastStatus => _$this._lastStatus;
  set lastStatus(String? lastStatus) => _$this._lastStatus = lastStatus;

  bool? _tokenConfigured;
  bool? get tokenConfigured => _$this._tokenConfigured;
  set tokenConfigured(bool? tokenConfigured) =>
      _$this._tokenConfigured = tokenConfigured;

  SmartHomeConfigResponseBuilder() {
    SmartHomeConfigResponse._defaults(this);
  }

  SmartHomeConfigResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _baseUrl = $v.baseUrl;
      _createdAt = $v.createdAt;
      _enabled = $v.enabled;
      _id = $v.id;
      _updatedAt = $v.updatedAt;
      _lastError = $v.lastError;
      _lastStatus = $v.lastStatus;
      _tokenConfigured = $v.tokenConfigured;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeConfigResponse other) {
    _$v = other as _$SmartHomeConfigResponse;
  }

  @override
  void update(void Function(SmartHomeConfigResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeConfigResponse build() => _build();

  _$SmartHomeConfigResponse _build() {
    final _$result =
        _$v ??
        _$SmartHomeConfigResponse._(
          baseUrl: BuiltValueNullFieldError.checkNotNull(
            baseUrl,
            r'SmartHomeConfigResponse',
            'baseUrl',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'SmartHomeConfigResponse',
            'createdAt',
          ),
          enabled: BuiltValueNullFieldError.checkNotNull(
            enabled,
            r'SmartHomeConfigResponse',
            'enabled',
          ),
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'SmartHomeConfigResponse',
            'id',
          ),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
            updatedAt,
            r'SmartHomeConfigResponse',
            'updatedAt',
          ),
          lastError: lastError,
          lastStatus: lastStatus,
          tokenConfigured: tokenConfigured,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
