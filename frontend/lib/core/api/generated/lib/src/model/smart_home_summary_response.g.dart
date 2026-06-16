// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_summary_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeSummaryResponse extends SmartHomeSummaryResponse {
  @override
  final int activeCount;
  @override
  final bool configured;
  @override
  final bool connected;
  @override
  final int unavailableCount;

  factory _$SmartHomeSummaryResponse(
          [void Function(SmartHomeSummaryResponseBuilder)? updates]) =>
      (SmartHomeSummaryResponseBuilder()..update(updates))._build();

  _$SmartHomeSummaryResponse._(
      {required this.activeCount,
      required this.configured,
      required this.connected,
      required this.unavailableCount})
      : super._();
  @override
  SmartHomeSummaryResponse rebuild(
          void Function(SmartHomeSummaryResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SmartHomeSummaryResponseBuilder toBuilder() =>
      SmartHomeSummaryResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeSummaryResponse &&
        activeCount == other.activeCount &&
        configured == other.configured &&
        connected == other.connected &&
        unavailableCount == other.unavailableCount;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, activeCount.hashCode);
    _$hash = $jc(_$hash, configured.hashCode);
    _$hash = $jc(_$hash, connected.hashCode);
    _$hash = $jc(_$hash, unavailableCount.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeSummaryResponse')
          ..add('activeCount', activeCount)
          ..add('configured', configured)
          ..add('connected', connected)
          ..add('unavailableCount', unavailableCount))
        .toString();
  }
}

class SmartHomeSummaryResponseBuilder
    implements
        Builder<SmartHomeSummaryResponse, SmartHomeSummaryResponseBuilder> {
  _$SmartHomeSummaryResponse? _$v;

  int? _activeCount;
  int? get activeCount => _$this._activeCount;
  set activeCount(int? activeCount) => _$this._activeCount = activeCount;

  bool? _configured;
  bool? get configured => _$this._configured;
  set configured(bool? configured) => _$this._configured = configured;

  bool? _connected;
  bool? get connected => _$this._connected;
  set connected(bool? connected) => _$this._connected = connected;

  int? _unavailableCount;
  int? get unavailableCount => _$this._unavailableCount;
  set unavailableCount(int? unavailableCount) =>
      _$this._unavailableCount = unavailableCount;

  SmartHomeSummaryResponseBuilder() {
    SmartHomeSummaryResponse._defaults(this);
  }

  SmartHomeSummaryResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _activeCount = $v.activeCount;
      _configured = $v.configured;
      _connected = $v.connected;
      _unavailableCount = $v.unavailableCount;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeSummaryResponse other) {
    _$v = other as _$SmartHomeSummaryResponse;
  }

  @override
  void update(void Function(SmartHomeSummaryResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeSummaryResponse build() => _build();

  _$SmartHomeSummaryResponse _build() {
    final _$result = _$v ??
        _$SmartHomeSummaryResponse._(
          activeCount: BuiltValueNullFieldError.checkNotNull(
              activeCount, r'SmartHomeSummaryResponse', 'activeCount'),
          configured: BuiltValueNullFieldError.checkNotNull(
              configured, r'SmartHomeSummaryResponse', 'configured'),
          connected: BuiltValueNullFieldError.checkNotNull(
              connected, r'SmartHomeSummaryResponse', 'connected'),
          unavailableCount: BuiltValueNullFieldError.checkNotNull(
              unavailableCount,
              r'SmartHomeSummaryResponse',
              'unavailableCount'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
