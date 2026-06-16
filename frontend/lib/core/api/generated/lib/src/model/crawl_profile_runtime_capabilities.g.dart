// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crawl_profile_runtime_capabilities.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const CrawlProfileRuntimeCapabilitiesModeEnum
    _$crawlProfileRuntimeCapabilitiesModeEnum_localGui =
    const CrawlProfileRuntimeCapabilitiesModeEnum._('localGui');
const CrawlProfileRuntimeCapabilitiesModeEnum
    _$crawlProfileRuntimeCapabilitiesModeEnum_headlessServer =
    const CrawlProfileRuntimeCapabilitiesModeEnum._('headlessServer');

CrawlProfileRuntimeCapabilitiesModeEnum
    _$crawlProfileRuntimeCapabilitiesModeEnumValueOf(String name) {
  switch (name) {
    case 'localGui':
      return _$crawlProfileRuntimeCapabilitiesModeEnum_localGui;
    case 'headlessServer':
      return _$crawlProfileRuntimeCapabilitiesModeEnum_headlessServer;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CrawlProfileRuntimeCapabilitiesModeEnum>
    _$crawlProfileRuntimeCapabilitiesModeEnumValues = BuiltSet<
        CrawlProfileRuntimeCapabilitiesModeEnum>(const <CrawlProfileRuntimeCapabilitiesModeEnum>[
  _$crawlProfileRuntimeCapabilitiesModeEnum_localGui,
  _$crawlProfileRuntimeCapabilitiesModeEnum_headlessServer,
]);

const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum
    _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_openLoginBrowser =
    const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum._(
        'openLoginBrowser');
const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum
    _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_importProfileBackup =
    const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum._(
        'importProfileBackup');

CrawlProfileRuntimeCapabilitiesRecommendedActionEnum
    _$crawlProfileRuntimeCapabilitiesRecommendedActionEnumValueOf(String name) {
  switch (name) {
    case 'openLoginBrowser':
      return _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_openLoginBrowser;
    case 'importProfileBackup':
      return _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_importProfileBackup;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<CrawlProfileRuntimeCapabilitiesRecommendedActionEnum>
    _$crawlProfileRuntimeCapabilitiesRecommendedActionEnumValues = BuiltSet<
        CrawlProfileRuntimeCapabilitiesRecommendedActionEnum>(const <CrawlProfileRuntimeCapabilitiesRecommendedActionEnum>[
  _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_openLoginBrowser,
  _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_importProfileBackup,
]);

Serializer<CrawlProfileRuntimeCapabilitiesModeEnum>
    _$crawlProfileRuntimeCapabilitiesModeEnumSerializer =
    _$CrawlProfileRuntimeCapabilitiesModeEnumSerializer();
Serializer<CrawlProfileRuntimeCapabilitiesRecommendedActionEnum>
    _$crawlProfileRuntimeCapabilitiesRecommendedActionEnumSerializer =
    _$CrawlProfileRuntimeCapabilitiesRecommendedActionEnumSerializer();

class _$CrawlProfileRuntimeCapabilitiesModeEnumSerializer
    implements PrimitiveSerializer<CrawlProfileRuntimeCapabilitiesModeEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'localGui': 'local_gui',
    'headlessServer': 'headless_server',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'local_gui': 'localGui',
    'headless_server': 'headlessServer',
  };

  @override
  final Iterable<Type> types = const <Type>[
    CrawlProfileRuntimeCapabilitiesModeEnum
  ];
  @override
  final String wireName = 'CrawlProfileRuntimeCapabilitiesModeEnum';

  @override
  Object serialize(Serializers serializers,
          CrawlProfileRuntimeCapabilitiesModeEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CrawlProfileRuntimeCapabilitiesModeEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CrawlProfileRuntimeCapabilitiesModeEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$CrawlProfileRuntimeCapabilitiesRecommendedActionEnumSerializer
    implements
        PrimitiveSerializer<
            CrawlProfileRuntimeCapabilitiesRecommendedActionEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'openLoginBrowser': 'open_login_browser',
    'importProfileBackup': 'import_profile_backup',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'open_login_browser': 'openLoginBrowser',
    'import_profile_backup': 'importProfileBackup',
  };

  @override
  final Iterable<Type> types = const <Type>[
    CrawlProfileRuntimeCapabilitiesRecommendedActionEnum
  ];
  @override
  final String wireName =
      'CrawlProfileRuntimeCapabilitiesRecommendedActionEnum';

  @override
  Object serialize(Serializers serializers,
          CrawlProfileRuntimeCapabilitiesRecommendedActionEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  CrawlProfileRuntimeCapabilitiesRecommendedActionEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      CrawlProfileRuntimeCapabilitiesRecommendedActionEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$CrawlProfileRuntimeCapabilities
    extends CrawlProfileRuntimeCapabilities {
  @override
  final CrawlProfileRuntimeCapabilitiesModeEnum mode;
  @override
  final String os;
  @override
  final CrawlProfileRuntimeCapabilitiesRecommendedActionEnum recommendedAction;
  @override
  final bool supportsLoginSession;
  @override
  final bool supportsProfileExport;
  @override
  final bool supportsProfileImport;

  factory _$CrawlProfileRuntimeCapabilities(
          [void Function(CrawlProfileRuntimeCapabilitiesBuilder)? updates]) =>
      (CrawlProfileRuntimeCapabilitiesBuilder()..update(updates))._build();

  _$CrawlProfileRuntimeCapabilities._(
      {required this.mode,
      required this.os,
      required this.recommendedAction,
      required this.supportsLoginSession,
      required this.supportsProfileExport,
      required this.supportsProfileImport})
      : super._();
  @override
  CrawlProfileRuntimeCapabilities rebuild(
          void Function(CrawlProfileRuntimeCapabilitiesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CrawlProfileRuntimeCapabilitiesBuilder toBuilder() =>
      CrawlProfileRuntimeCapabilitiesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CrawlProfileRuntimeCapabilities &&
        mode == other.mode &&
        os == other.os &&
        recommendedAction == other.recommendedAction &&
        supportsLoginSession == other.supportsLoginSession &&
        supportsProfileExport == other.supportsProfileExport &&
        supportsProfileImport == other.supportsProfileImport;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, os.hashCode);
    _$hash = $jc(_$hash, recommendedAction.hashCode);
    _$hash = $jc(_$hash, supportsLoginSession.hashCode);
    _$hash = $jc(_$hash, supportsProfileExport.hashCode);
    _$hash = $jc(_$hash, supportsProfileImport.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CrawlProfileRuntimeCapabilities')
          ..add('mode', mode)
          ..add('os', os)
          ..add('recommendedAction', recommendedAction)
          ..add('supportsLoginSession', supportsLoginSession)
          ..add('supportsProfileExport', supportsProfileExport)
          ..add('supportsProfileImport', supportsProfileImport))
        .toString();
  }
}

class CrawlProfileRuntimeCapabilitiesBuilder
    implements
        Builder<CrawlProfileRuntimeCapabilities,
            CrawlProfileRuntimeCapabilitiesBuilder> {
  _$CrawlProfileRuntimeCapabilities? _$v;

  CrawlProfileRuntimeCapabilitiesModeEnum? _mode;
  CrawlProfileRuntimeCapabilitiesModeEnum? get mode => _$this._mode;
  set mode(CrawlProfileRuntimeCapabilitiesModeEnum? mode) =>
      _$this._mode = mode;

  String? _os;
  String? get os => _$this._os;
  set os(String? os) => _$this._os = os;

  CrawlProfileRuntimeCapabilitiesRecommendedActionEnum? _recommendedAction;
  CrawlProfileRuntimeCapabilitiesRecommendedActionEnum? get recommendedAction =>
      _$this._recommendedAction;
  set recommendedAction(
          CrawlProfileRuntimeCapabilitiesRecommendedActionEnum?
              recommendedAction) =>
      _$this._recommendedAction = recommendedAction;

  bool? _supportsLoginSession;
  bool? get supportsLoginSession => _$this._supportsLoginSession;
  set supportsLoginSession(bool? supportsLoginSession) =>
      _$this._supportsLoginSession = supportsLoginSession;

  bool? _supportsProfileExport;
  bool? get supportsProfileExport => _$this._supportsProfileExport;
  set supportsProfileExport(bool? supportsProfileExport) =>
      _$this._supportsProfileExport = supportsProfileExport;

  bool? _supportsProfileImport;
  bool? get supportsProfileImport => _$this._supportsProfileImport;
  set supportsProfileImport(bool? supportsProfileImport) =>
      _$this._supportsProfileImport = supportsProfileImport;

  CrawlProfileRuntimeCapabilitiesBuilder() {
    CrawlProfileRuntimeCapabilities._defaults(this);
  }

  CrawlProfileRuntimeCapabilitiesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mode = $v.mode;
      _os = $v.os;
      _recommendedAction = $v.recommendedAction;
      _supportsLoginSession = $v.supportsLoginSession;
      _supportsProfileExport = $v.supportsProfileExport;
      _supportsProfileImport = $v.supportsProfileImport;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CrawlProfileRuntimeCapabilities other) {
    _$v = other as _$CrawlProfileRuntimeCapabilities;
  }

  @override
  void update(void Function(CrawlProfileRuntimeCapabilitiesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CrawlProfileRuntimeCapabilities build() => _build();

  _$CrawlProfileRuntimeCapabilities _build() {
    final _$result = _$v ??
        _$CrawlProfileRuntimeCapabilities._(
          mode: BuiltValueNullFieldError.checkNotNull(
              mode, r'CrawlProfileRuntimeCapabilities', 'mode'),
          os: BuiltValueNullFieldError.checkNotNull(
              os, r'CrawlProfileRuntimeCapabilities', 'os'),
          recommendedAction: BuiltValueNullFieldError.checkNotNull(
              recommendedAction,
              r'CrawlProfileRuntimeCapabilities',
              'recommendedAction'),
          supportsLoginSession: BuiltValueNullFieldError.checkNotNull(
              supportsLoginSession,
              r'CrawlProfileRuntimeCapabilities',
              'supportsLoginSession'),
          supportsProfileExport: BuiltValueNullFieldError.checkNotNull(
              supportsProfileExport,
              r'CrawlProfileRuntimeCapabilities',
              'supportsProfileExport'),
          supportsProfileImport: BuiltValueNullFieldError.checkNotNull(
              supportsProfileImport,
              r'CrawlProfileRuntimeCapabilities',
              'supportsProfileImport'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
