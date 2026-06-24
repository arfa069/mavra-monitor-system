// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_test_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CrawlProfileTestResponseStatusEnum
_$crawlProfileTestResponseStatusEnum_ready =
    const CrawlProfileTestResponseStatusEnum._('ready');
const CrawlProfileTestResponseStatusEnum
_$crawlProfileTestResponseStatusEnum_loginRequired =
    const CrawlProfileTestResponseStatusEnum._('loginRequired');
const CrawlProfileTestResponseStatusEnum
_$crawlProfileTestResponseStatusEnum_riskBlocked =
    const CrawlProfileTestResponseStatusEnum._('riskBlocked');
const CrawlProfileTestResponseStatusEnum
_$crawlProfileTestResponseStatusEnum_error =
    const CrawlProfileTestResponseStatusEnum._('error');

CrawlProfileTestResponseStatusEnum _$crawlProfileTestResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ready':
      return _$crawlProfileTestResponseStatusEnum_ready;
    case 'loginRequired':
      return _$crawlProfileTestResponseStatusEnum_loginRequired;
    case 'riskBlocked':
      return _$crawlProfileTestResponseStatusEnum_riskBlocked;
    case 'error':
      return _$crawlProfileTestResponseStatusEnum_error;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CrawlProfileTestResponseStatusEnum>
_$crawlProfileTestResponseStatusEnumValues =
    BuiltSet<CrawlProfileTestResponseStatusEnum>(
      const <CrawlProfileTestResponseStatusEnum>[
        _$crawlProfileTestResponseStatusEnum_ready,
        _$crawlProfileTestResponseStatusEnum_loginRequired,
        _$crawlProfileTestResponseStatusEnum_riskBlocked,
        _$crawlProfileTestResponseStatusEnum_error,
      ],
    );

Serializer<CrawlProfileTestResponseStatusEnum>
_$crawlProfileTestResponseStatusEnumSerializer =
    _$CrawlProfileTestResponseStatusEnumSerializer();

class _$CrawlProfileTestResponseStatusEnumSerializer
    implements PrimitiveSerializer<CrawlProfileTestResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'ready': 'ready',
    'loginRequired': 'login_required',
    'riskBlocked': 'risk_blocked',
    'error': 'error',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ready': 'ready',
    'login_required': 'loginRequired',
    'risk_blocked': 'riskBlocked',
    'error': 'error',
  };

  @override
  final Iterable<Type> types = const <Type>[CrawlProfileTestResponseStatusEnum];
  @override
  final String wireName = 'CrawlProfileTestResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileTestResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CrawlProfileTestResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CrawlProfileTestResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CrawlProfileTestResponse extends CrawlProfileTestResponse {
  @override
  final String platform;
  @override
  final String profileKey;
  @override
  final CrawlProfileTestResponseStatusEnum status;
  @override
  final String? message;

  factory _$CrawlProfileTestResponse([
    void Function(CrawlProfileTestResponseBuilder)? updates,
  ]) => (CrawlProfileTestResponseBuilder()..update(updates))._build();

  _$CrawlProfileTestResponse._({
    required this.platform,
    required this.profileKey,
    required this.status,
    this.message,
  }) : super._();
  @override
  CrawlProfileTestResponse rebuild(
    void Function(CrawlProfileTestResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CrawlProfileTestResponseBuilder toBuilder() =>
      CrawlProfileTestResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileTestResponse &&
        platform == other.platform &&
        profileKey == other.profileKey &&
        status == other.status &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileTestResponse')
          ..add('platform', platform)
          ..add('profileKey', profileKey)
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class CrawlProfileTestResponseBuilder
    implements
        Builder<CrawlProfileTestResponse, CrawlProfileTestResponseBuilder> {
  _$CrawlProfileTestResponse? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  CrawlProfileTestResponseStatusEnum? _status;
  CrawlProfileTestResponseStatusEnum? get status => _$this._status;
  set status(CrawlProfileTestResponseStatusEnum? status) =>
      _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  CrawlProfileTestResponseBuilder() {
    CrawlProfileTestResponse._defaults(this);
  }

  CrawlProfileTestResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _profileKey = $v.profileKey;
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileTestResponse other) {
    _$v = other as _$CrawlProfileTestResponse;
  }

  @override
  void update(void Function(CrawlProfileTestResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileTestResponse build() => _build();

  _$CrawlProfileTestResponse _build() {
    final _$result =
        _$v ??
        _$CrawlProfileTestResponse._(
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'CrawlProfileTestResponse',
            'platform',
          ),
          profileKey: BuiltValueNullFieldError.checkNotNull(
            profileKey,
            r'CrawlProfileTestResponse',
            'profileKey',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'CrawlProfileTestResponse',
            'status',
          ),
          message: message,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
