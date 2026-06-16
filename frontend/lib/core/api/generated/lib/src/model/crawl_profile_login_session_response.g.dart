// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_login_session_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CrawlProfileLoginSessionResponseStatusEnum
_$crawlProfileLoginSessionResponseStatusEnum_active =
    const CrawlProfileLoginSessionResponseStatusEnum._('active');
const CrawlProfileLoginSessionResponseStatusEnum
_$crawlProfileLoginSessionResponseStatusEnum_closed =
    const CrawlProfileLoginSessionResponseStatusEnum._('closed');
const CrawlProfileLoginSessionResponseStatusEnum
_$crawlProfileLoginSessionResponseStatusEnum_failed =
    const CrawlProfileLoginSessionResponseStatusEnum._('failed');

CrawlProfileLoginSessionResponseStatusEnum
_$crawlProfileLoginSessionResponseStatusEnumValueOf(String name) {
  switch (name) {
    case 'active':
      return _$crawlProfileLoginSessionResponseStatusEnum_active;
    case 'closed':
      return _$crawlProfileLoginSessionResponseStatusEnum_closed;
    case 'failed':
      return _$crawlProfileLoginSessionResponseStatusEnum_failed;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CrawlProfileLoginSessionResponseStatusEnum>
_$crawlProfileLoginSessionResponseStatusEnumValues =
    BuiltSet<CrawlProfileLoginSessionResponseStatusEnum>(
      const <CrawlProfileLoginSessionResponseStatusEnum>[
        _$crawlProfileLoginSessionResponseStatusEnum_active,
        _$crawlProfileLoginSessionResponseStatusEnum_closed,
        _$crawlProfileLoginSessionResponseStatusEnum_failed,
      ],
    );

Serializer<CrawlProfileLoginSessionResponseStatusEnum>
_$crawlProfileLoginSessionResponseStatusEnumSerializer =
    _$CrawlProfileLoginSessionResponseStatusEnumSerializer();

class _$CrawlProfileLoginSessionResponseStatusEnumSerializer
    implements PrimitiveSerializer<CrawlProfileLoginSessionResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'active': 'active',
    'closed': 'closed',
    'failed': 'failed',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'active': 'active',
    'closed': 'closed',
    'failed': 'failed',
  };

  @override
  final Iterable<Type> types = const <Type>[
    CrawlProfileLoginSessionResponseStatusEnum,
  ];
  @override
  final String wireName = 'CrawlProfileLoginSessionResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileLoginSessionResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  CrawlProfileLoginSessionResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => CrawlProfileLoginSessionResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$CrawlProfileLoginSessionResponse
    extends CrawlProfileLoginSessionResponse {
  @override
  final String platform;
  @override
  final String profileKey;
  @override
  final String startUrl;
  @override
  final CrawlProfileLoginSessionResponseStatusEnum status;
  @override
  final String? message;

  factory _$CrawlProfileLoginSessionResponse([
    void Function(CrawlProfileLoginSessionResponseBuilder)? updates,
  ]) => (CrawlProfileLoginSessionResponseBuilder()..update(updates))._build();

  _$CrawlProfileLoginSessionResponse._({
    required this.platform,
    required this.profileKey,
    required this.startUrl,
    required this.status,
    this.message,
  }) : super._();
  @override
  CrawlProfileLoginSessionResponse rebuild(
    void Function(CrawlProfileLoginSessionResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  CrawlProfileLoginSessionResponseBuilder toBuilder() =>
      CrawlProfileLoginSessionResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileLoginSessionResponse &&
        platform == other.platform &&
        profileKey == other.profileKey &&
        startUrl == other.startUrl &&
        status == other.status &&
        message == other.message;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, platform.hashCode);
    _$hash = $jc(_$hash, profileKey.hashCode);
    _$hash = $jc(_$hash, startUrl.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileLoginSessionResponse')
          ..add('platform', platform)
          ..add('profileKey', profileKey)
          ..add('startUrl', startUrl)
          ..add('status', status)
          ..add('message', message))
        .toString();
  }
}

class CrawlProfileLoginSessionResponseBuilder
    implements
        Builder<
          CrawlProfileLoginSessionResponse,
          CrawlProfileLoginSessionResponseBuilder
        > {
  _$CrawlProfileLoginSessionResponse? _$v;

  String? _platform;
  String? get platform => _$this._platform;
  set platform(String? platform) => _$this._platform = platform;

  String? _profileKey;
  String? get profileKey => _$this._profileKey;
  set profileKey(String? profileKey) => _$this._profileKey = profileKey;

  String? _startUrl;
  String? get startUrl => _$this._startUrl;
  set startUrl(String? startUrl) => _$this._startUrl = startUrl;

  CrawlProfileLoginSessionResponseStatusEnum? _status;
  CrawlProfileLoginSessionResponseStatusEnum? get status => _$this._status;
  set status(CrawlProfileLoginSessionResponseStatusEnum? status) =>
      _$this._status = status;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  CrawlProfileLoginSessionResponseBuilder() {
    CrawlProfileLoginSessionResponse._defaults(this);
  }

  CrawlProfileLoginSessionResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _platform = $v.platform;
      _profileKey = $v.profileKey;
      _startUrl = $v.startUrl;
      _status = $v.status;
      _message = $v.message;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileLoginSessionResponse other) {
    _$v = other as _$CrawlProfileLoginSessionResponse;
  }

  @override
  void update(void Function(CrawlProfileLoginSessionResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileLoginSessionResponse build() => _build();

  _$CrawlProfileLoginSessionResponse _build() {
    final _$result =
        _$v ??
        _$CrawlProfileLoginSessionResponse._(
          platform: BuiltValueNullFieldError.checkNotNull(
            platform,
            r'CrawlProfileLoginSessionResponse',
            'platform',
          ),
          profileKey: BuiltValueNullFieldError.checkNotNull(
            profileKey,
            r'CrawlProfileLoginSessionResponse',
            'profileKey',
          ),
          startUrl: BuiltValueNullFieldError.checkNotNull(
            startUrl,
            r'CrawlProfileLoginSessionResponse',
            'startUrl',
          ),
          status: BuiltValueNullFieldError.checkNotNull(
            status,
            r'CrawlProfileLoginSessionResponse',
            'status',
          ),
          message: message,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
