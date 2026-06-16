// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_config_test_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeConfigTestResponse extends SmartHomeConfigTestResponse {
  @override
  final String message;
  @override
  final bool ok;
  @override
  final String? homeAssistantVersion;

  factory _$SmartHomeConfigTestResponse(
          [void Function(SmartHomeConfigTestResponseBuilder)? updates]) =>
      (SmartHomeConfigTestResponseBuilder()..update(updates))._build();

  _$SmartHomeConfigTestResponse._(
      {required this.message, required this.ok, this.homeAssistantVersion})
      : super._();
  @override
  SmartHomeConfigTestResponse rebuild(
          void Function(SmartHomeConfigTestResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SmartHomeConfigTestResponseBuilder toBuilder() =>
      SmartHomeConfigTestResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeConfigTestResponse &&
        message == other.message &&
        ok == other.ok &&
        homeAssistantVersion == other.homeAssistantVersion;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, homeAssistantVersion.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeConfigTestResponse')
          ..add('message', message)
          ..add('ok', ok)
          ..add('homeAssistantVersion', homeAssistantVersion))
        .toString();
  }
}

class SmartHomeConfigTestResponseBuilder
    implements
        Builder<SmartHomeConfigTestResponse,
            SmartHomeConfigTestResponseBuilder> {
  _$SmartHomeConfigTestResponse? _$v;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  String? _homeAssistantVersion;
  String? get homeAssistantVersion => _$this._homeAssistantVersion;
  set homeAssistantVersion(String? homeAssistantVersion) =>
      _$this._homeAssistantVersion = homeAssistantVersion;

  SmartHomeConfigTestResponseBuilder() {
    SmartHomeConfigTestResponse._defaults(this);
  }

  SmartHomeConfigTestResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _message = $v.message;
      _ok = $v.ok;
      _homeAssistantVersion = $v.homeAssistantVersion;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeConfigTestResponse other) {
    _$v = other as _$SmartHomeConfigTestResponse;
  }

  @override
  void update(void Function(SmartHomeConfigTestResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeConfigTestResponse build() => _build();

  _$SmartHomeConfigTestResponse _build() {
    final _$result = _$v ??
        _$SmartHomeConfigTestResponse._(
          message: BuiltValueNullFieldError.checkNotNull(
              message, r'SmartHomeConfigTestResponse', 'message'),
          ok: BuiltValueNullFieldError.checkNotNull(
              ok, r'SmartHomeConfigTestResponse', 'ok'),
          homeAssistantVersion: homeAssistantVersion,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
