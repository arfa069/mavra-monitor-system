// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'we_chat_exchange_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeChatExchangeRequest extends WeChatExchangeRequest {
  @override
  final String exchangeCode;
  @override
  final LoginClientKind? clientKind;

  factory _$WeChatExchangeRequest([
    void Function(WeChatExchangeRequestBuilder)? updates,
  ]) => (WeChatExchangeRequestBuilder()..update(updates))._build();

  _$WeChatExchangeRequest._({required this.exchangeCode, this.clientKind})
    : super._();
  @override
  WeChatExchangeRequest rebuild(
    void Function(WeChatExchangeRequestBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WeChatExchangeRequestBuilder toBuilder() =>
      WeChatExchangeRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeChatExchangeRequest &&
        exchangeCode == other.exchangeCode &&
        clientKind == other.clientKind;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, exchangeCode.hashCode);
    _$hash = $jc(_$hash, clientKind.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeChatExchangeRequest')
          ..add('exchangeCode', exchangeCode)
          ..add('clientKind', clientKind))
        .toString();
  }
}

class WeChatExchangeRequestBuilder
    implements Builder<WeChatExchangeRequest, WeChatExchangeRequestBuilder> {
  _$WeChatExchangeRequest? _$v;

  String? _exchangeCode;
  String? get exchangeCode => _$this._exchangeCode;
  set exchangeCode(String? exchangeCode) => _$this._exchangeCode = exchangeCode;

  LoginClientKind? _clientKind;
  LoginClientKind? get clientKind => _$this._clientKind;
  set clientKind(LoginClientKind? clientKind) =>
      _$this._clientKind = clientKind;

  WeChatExchangeRequestBuilder() {
    WeChatExchangeRequest._defaults(this);
  }

  WeChatExchangeRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _exchangeCode = $v.exchangeCode;
      _clientKind = $v.clientKind;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeChatExchangeRequest other) {
    _$v = other as _$WeChatExchangeRequest;
  }

  @override
  void update(void Function(WeChatExchangeRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeChatExchangeRequest build() => _build();

  _$WeChatExchangeRequest _build() {
    final _$result =
        _$v ??
        _$WeChatExchangeRequest._(
          exchangeCode: BuiltValueNullFieldError.checkNotNull(
            exchangeCode,
            r'WeChatExchangeRequest',
            'exchangeCode',
          ),
          clientKind: clientKind,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
