// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CrawlProfileUpdateStatusEnum _$crawlProfileUpdateStatusEnum_available =
    const CrawlProfileUpdateStatusEnum._('available');
const CrawlProfileUpdateStatusEnum
    _$crawlProfileUpdateStatusEnum_loginRequired =
    const CrawlProfileUpdateStatusEnum._('loginRequired');
const CrawlProfileUpdateStatusEnum _$crawlProfileUpdateStatusEnum_disabled =
    const CrawlProfileUpdateStatusEnum._('disabled');

CrawlProfileUpdateStatusEnum _$crawlProfileUpdateStatusEnumValueOf(
    String name) {
  switch (name) {
    case 'available':
      return _$crawlProfileUpdateStatusEnum_available;
    case 'loginRequired':
      return _$crawlProfileUpdateStatusEnum_loginRequired;
    case 'disabled':
      return _$crawlProfileUpdateStatusEnum_disabled;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CrawlProfileUpdateStatusEnum>
    _$crawlProfileUpdateStatusEnumValues =
    BuiltSet<CrawlProfileUpdateStatusEnum>(const <CrawlProfileUpdateStatusEnum>[
  _$crawlProfileUpdateStatusEnum_available,
  _$crawlProfileUpdateStatusEnum_loginRequired,
  _$crawlProfileUpdateStatusEnum_disabled,
]);

Serializer<CrawlProfileUpdateStatusEnum>
    _$crawlProfileUpdateStatusEnumSerializer =
    _$CrawlProfileUpdateStatusEnumSerializer();

class _$CrawlProfileUpdateStatusEnumSerializer
    implements PrimitiveSerializer<CrawlProfileUpdateStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'available': 'available',
    'loginRequired': 'login_required',
    'disabled': 'disabled',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'available': 'available',
    'login_required': 'loginRequired',
    'disabled': 'disabled',
  };

  @override
  final Iterable<Type> types = const <Type>[CrawlProfileUpdateStatusEnum];
  @override
  final String wireName = 'CrawlProfileUpdateStatusEnum';

  @override
  Object serialize(Serializers serializers, CrawlProfileUpdateStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CrawlProfileUpdateStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CrawlProfileUpdateStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$CrawlProfileUpdate extends CrawlProfileUpdate {
  @override
  final String? lastError;
  @override
  final String? platformHint;
  @override
  final CrawlProfileUpdateStatusEnum? status;

  factory _$CrawlProfileUpdate(
          [void Function(CrawlProfileUpdateBuilder)? updates]) =>
      (CrawlProfileUpdateBuilder()..update(updates))._build();

  _$CrawlProfileUpdate._({this.lastError, this.platformHint, this.status})
      : super._();
  @override
  CrawlProfileUpdate rebuild(
          void Function(CrawlProfileUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlProfileUpdateBuilder toBuilder() =>
      CrawlProfileUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileUpdate &&
        lastError == other.lastError &&
        platformHint == other.platformHint &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, lastError.hashCode);
    _$hash = $jc(_$hash, platformHint.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileUpdate')
          ..add('lastError', lastError)
          ..add('platformHint', platformHint)
          ..add('status', status))
        .toString();
  }
}

class CrawlProfileUpdateBuilder
    implements Builder<CrawlProfileUpdate, CrawlProfileUpdateBuilder> {
  _$CrawlProfileUpdate? _$v;

  String? _lastError;
  String? get lastError => _$this._lastError;
  set lastError(String? lastError) => _$this._lastError = lastError;

  String? _platformHint;
  String? get platformHint => _$this._platformHint;
  set platformHint(String? platformHint) => _$this._platformHint = platformHint;

  CrawlProfileUpdateStatusEnum? _status;
  CrawlProfileUpdateStatusEnum? get status => _$this._status;
  set status(CrawlProfileUpdateStatusEnum? status) => _$this._status = status;

  CrawlProfileUpdateBuilder() {
    CrawlProfileUpdate._defaults(this);
  }

  CrawlProfileUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lastError = $v.lastError;
      _platformHint = $v.platformHint;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileUpdate other) {
    _$v = other as _$CrawlProfileUpdate;
  }

  @override
  void update(void Function(CrawlProfileUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileUpdate build() => _build();

  _$CrawlProfileUpdate _build() {
    final _$result = _$v ??
        _$CrawlProfileUpdate._(
          lastError: lastError,
          platformHint: platformHint,
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
