// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CrawlProfileResponseStatusEnum
    _$crawlProfileResponseStatusEnum_available =
    const CrawlProfileResponseStatusEnum._('available');
const CrawlProfileResponseStatusEnum _$crawlProfileResponseStatusEnum_leased =
    const CrawlProfileResponseStatusEnum._('leased');
const CrawlProfileResponseStatusEnum
    _$crawlProfileResponseStatusEnum_loginRequired =
    const CrawlProfileResponseStatusEnum._('loginRequired');
const CrawlProfileResponseStatusEnum
    _$crawlProfileResponseStatusEnum_coolingDown =
    const CrawlProfileResponseStatusEnum._('coolingDown');
const CrawlProfileResponseStatusEnum _$crawlProfileResponseStatusEnum_disabled =
    const CrawlProfileResponseStatusEnum._('disabled');

CrawlProfileResponseStatusEnum _$crawlProfileResponseStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'available':
      return _$crawlProfileResponseStatusEnum_available;
    case 'leased':
      return _$crawlProfileResponseStatusEnum_leased;
    case 'loginRequired':
      return _$crawlProfileResponseStatusEnum_loginRequired;
    case 'coolingDown':
      return _$crawlProfileResponseStatusEnum_coolingDown;
    case 'disabled':
      return _$crawlProfileResponseStatusEnum_disabled;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CrawlProfileResponseStatusEnum>
    _$crawlProfileResponseStatusEnumValues = BuiltSet<
        CrawlProfileResponseStatusEnum>(const <CrawlProfileResponseStatusEnum>[
  _$crawlProfileResponseStatusEnum_available,
  _$crawlProfileResponseStatusEnum_leased,
  _$crawlProfileResponseStatusEnum_loginRequired,
  _$crawlProfileResponseStatusEnum_coolingDown,
  _$crawlProfileResponseStatusEnum_disabled,
]);

Serializer<CrawlProfileResponseStatusEnum>
    _$crawlProfileResponseStatusEnumSerializer =
    _$CrawlProfileResponseStatusEnumSerializer();

class _$CrawlProfileResponseStatusEnumSerializer
    implements PrimitiveSerializer<CrawlProfileResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'available': 'available',
    'leased': 'leased',
    'loginRequired': 'login_required',
    'coolingDown': 'cooling_down',
    'disabled': 'disabled',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'available': 'available',
    'leased': 'leased',
    'login_required': 'loginRequired',
    'cooling_down': 'coolingDown',
    'disabled': 'disabled',
  };

  @override
  final Iterable<Type> types = const <Type>[CrawlProfileResponseStatusEnum];
  @override
  final String wireName = 'CrawlProfileResponseStatusEnum';

  @override
  Object serialize(
          Serializers serializers, CrawlProfileResponseStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CrawlProfileResponseStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CrawlProfileResponseStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$CrawlProfileResponse extends CrawlProfileResponse {
  @override
  final DateTime createdAt;
  @override
  final String? lastError;
  @override
  final DateTime? lastUsedAt;
  @override
  final String? leaseOwner;
  @override
  final String? leaseTaskId;
  @override
  final DateTime? leaseUntil;
  @override
  final String? platformHint;
  @override
  final String profileDir;
  @override
  final String profileKey;
  @override
  final CrawlProfileResponseStatusEnum status;
  @override
  final DateTime updatedAt;

  factory _$CrawlProfileResponse(
          [void Function(CrawlProfileResponseBuilder)? updates]) =>
      (CrawlProfileResponseBuilder()..update(updates))._build();

  _$CrawlProfileResponse._(
      {required this.createdAt,
      this.lastError,
      this.lastUsedAt,
      this.leaseOwner,
      this.leaseTaskId,
      this.leaseUntil,
      this.platformHint,
      required this.profileDir,
      required this.profileKey,
      required this.status,
      required this.updatedAt})
      : super._();
  @override
  CrawlProfileResponse rebuild(
          void Function(CrawlProfileResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlProfileResponseBuilder toBuilder() =>
      CrawlProfileResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileResponse &&
        createdAt == other.createdAt &&
        lastError == other.lastError &&
        lastUsedAt == other.lastUsedAt &&
        leaseOwner == other.leaseOwner &&
        leaseTaskId == other.leaseTaskId &&
        leaseUntil == other.leaseUntil &&
        platformHint == other.platformHint &&
        profileDir == other.profileDir &&
        profileKey == other.profileKey &&
        status == other.status &&
        updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, lastError.hashCode);
    _$hash = $jc(_$hash, lastUsedAt.hashCode);
    _$hash = $jc(_$hash, leaseOwner.hashCode);
    _$hash = $jc(_$hash, leaseTaskId.hashCode);
    _$hash = $jc(_$hash, leaseUntil.hashCode);
    _$hash = $jc(_$hash, platformHint.hashCode);
    _$hash = $jc(_$hash, profileDir.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileResponse')
          ..add('createdAt', createdAt)
          ..add('lastError', lastError)
          ..add('lastUsedAt', lastUsedAt)
          ..add('leaseOwner', leaseOwner)
          ..add('leaseTaskId', leaseTaskId)
          ..add('leaseUntil', leaseUntil)
          ..add('platformHint', platformHint)
          ..add('profileDir', profileDir)
          ..add('profileKey', profileKey)
          ..add('status', status)
          ..add('updatedAt', updatedAt))
        .toString();
  }
}

class CrawlProfileResponseBuilder
    implements Builder<CrawlProfileResponse, CrawlProfileResponseBuilder> {
  _$CrawlProfileResponse? _$v;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _lastError;
  String? get lastError => _$this._lastError;
  set lastError(String? lastError) => _$this._lastError = lastError;

  DateTime? _lastUsedAt;
  DateTime? get lastUsedAt => _$this._lastUsedAt;
  set lastUsedAt(DateTime? lastUsedAt) => _$this._lastUsedAt = lastUsedAt;

  String? _leaseOwner;
  String? get leaseOwner => _$this._leaseOwner;
  set leaseOwner(String? leaseOwner) => _$this._leaseOwner = leaseOwner;

  String? _leaseTaskId;
  String? get leaseTaskId => _$this._leaseTaskId;
  set leaseTaskId(String? leaseTaskId) => _$this._leaseTaskId = leaseTaskId;

  DateTime? _leaseUntil;
  DateTime? get leaseUntil => _$this._leaseUntil;
  set leaseUntil(DateTime? leaseUntil) => _$this._leaseUntil = leaseUntil;

  String? _platformHint;
  String? get platformHint => _$this._platformHint;
  set platformHint(String? platformHint) => _$this._platformHint = platformHint;

  String? _profileDir;
  String? get profileDir => _$this._profileDir;
  set profileDir(String? profileDir) => _$this._profileDir = profileDir;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  CrawlProfileResponseStatusEnum? _status;
  CrawlProfileResponseStatusEnum? get status => _$this._status;
  set status(CrawlProfileResponseStatusEnum? status) => _$this._status = status;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  CrawlProfileResponseBuilder() {
    CrawlProfileResponse._defaults(this);
  }

  CrawlProfileResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _createdAt = $v.createdAt;
      _lastError = $v.lastError;
      _lastUsedAt = $v.lastUsedAt;
      _leaseOwner = $v.leaseOwner;
      _leaseTaskId = $v.leaseTaskId;
      _leaseUntil = $v.leaseUntil;
      _platformHint = $v.platformHint;
      _profileDir = $v.profileDir;
      _profileKey = $v.profileKey;
      _status = $v.status;
      _updatedAt = $v.updatedAt;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileResponse other) {
    _$v = other as _$CrawlProfileResponse;
  }

  @override
  void update(void Function(CrawlProfileResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileResponse build() => _build();

  _$CrawlProfileResponse _build() {
    final _$result = _$v ??
        _$CrawlProfileResponse._(
          createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt, r'CrawlProfileResponse', 'createdAt'),
          lastError: lastError,
          lastUsedAt: lastUsedAt,
          leaseOwner: leaseOwner,
          leaseTaskId: leaseTaskId,
          leaseUntil: leaseUntil,
          platformHint: platformHint,
          profileDir: BuiltValueNullFieldError.checkNotNull(
              profileDir, r'CrawlProfileResponse', 'profileDir'),
          profileKey: BuiltValueNullFieldError.checkNotNull(
              profileKey, r'CrawlProfileResponse', 'profileKey'),
          status: BuiltValueNullFieldError.checkNotNull(
              status, r'CrawlProfileResponse', 'status'),
          updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt, r'CrawlProfileResponse', 'updatedAt'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
