// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_config_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeConfigUpdate extends SmartHomeConfigUpdate {
  @override
  final String baseUrl;
  @override
  final bool? enabled;
  @override
  final String? token;

  factory _$SmartHomeConfigUpdate([
    void Function(SmartHomeConfigUpdateBuilder)? updates,
  ]) => (SmartHomeConfigUpdateBuilder()..update(updates))._build();

  _$SmartHomeConfigUpdate._({required this.baseUrl, this.enabled, this.token})
    : super._();
  @override
  SmartHomeConfigUpdate rebuild(
    void Function(SmartHomeConfigUpdateBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SmartHomeConfigUpdateBuilder toBuilder() =>
      SmartHomeConfigUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeConfigUpdate &&
        baseUrl == other.baseUrl &&
        enabled == other.enabled &&
        token == other.token;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, baseUrl.hashCode);
    _$hash = $jc(_$hash, enabled.hashCode);
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeConfigUpdate')
          ..add('baseUrl', baseUrl)
          ..add('enabled', enabled)
          ..add('token', token))
        .toString();
  }
}

class SmartHomeConfigUpdateBuilder
    implements Builder<SmartHomeConfigUpdate, SmartHomeConfigUpdateBuilder> {
  _$SmartHomeConfigUpdate? _$v;

  String? _baseUrl;
  String? get baseUrl => _$this._baseUrl;
  set baseUrl(String? baseUrl) => _$this._baseUrl = baseUrl;

  bool? _enabled;
  bool? get enabled => _$this._enabled;
  set enabled(bool? enabled) => _$this._enabled = enabled;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  SmartHomeConfigUpdateBuilder() {
    SmartHomeConfigUpdate._defaults(this);
  }

  SmartHomeConfigUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _baseUrl = $v.baseUrl;
      _enabled = $v.enabled;
      _token = $v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeConfigUpdate other) {
    _$v = other as _$SmartHomeConfigUpdate;
  }

  @override
  void update(void Function(SmartHomeConfigUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeConfigUpdate build() => _build();

  _$SmartHomeConfigUpdate _build() {
    final _$result =
        _$v ??
        _$SmartHomeConfigUpdate._(
          baseUrl: BuiltValueNullFieldError.checkNotNull(
            baseUrl,
            r'SmartHomeConfigUpdate',
            'baseUrl',
          ),
          enabled: enabled,
          token: token,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
