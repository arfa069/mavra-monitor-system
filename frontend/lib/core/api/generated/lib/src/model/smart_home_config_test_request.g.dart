// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_config_test_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeConfigTestRequest extends SmartHomeConfigTestRequest {
  @override
  final String? baseUrl;
  @override
  final String? token;

  factory _$SmartHomeConfigTestRequest([
    void Function(SmartHomeConfigTestRequestBuilder)? updates,
  ]) => (SmartHomeConfigTestRequestBuilder()..update(updates))._build();

  _$SmartHomeConfigTestRequest._({this.baseUrl, this.token}) : super._();
  @override
  SmartHomeConfigTestRequest rebuild(
    void Function(SmartHomeConfigTestRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SmartHomeConfigTestRequestBuilder toBuilder() =>
      SmartHomeConfigTestRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeConfigTestRequest &&
        baseUrl == other.baseUrl &&
        token == other.token;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, baseUrl.hashCode);
    _$hash = $jc(_$hash, token.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeConfigTestRequest')
          ..add('baseUrl', baseUrl)
          ..add('token', token))
        .toString();
  }
}

class SmartHomeConfigTestRequestBuilder
    implements
        Builder<SmartHomeConfigTestRequest, SmartHomeConfigTestRequestBuilder> {
  _$SmartHomeConfigTestRequest? _$v;

  String? _baseUrl;
  String? get baseUrl => _$this._baseUrl;
  set baseUrl(String? baseUrl) => _$this._baseUrl = baseUrl;

  String? _token;
  String? get token => _$this._token;
  set token(String? token) => _$this._token = token;

  SmartHomeConfigTestRequestBuilder() {
    SmartHomeConfigTestRequest._defaults(this);
  }

  SmartHomeConfigTestRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _baseUrl = $v.baseUrl;
      _token = $v.token;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeConfigTestRequest other) {
    _$v = other as _$SmartHomeConfigTestRequest;
  }

  @override
  void update(void Function(SmartHomeConfigTestRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeConfigTestRequest build() => _build();

  _$SmartHomeConfigTestRequest _build() {
    final _$result =
        _$v ?? _$SmartHomeConfigTestRequest._(baseUrl: baseUrl, token: token);
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
