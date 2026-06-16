// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'we_chat_qr_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeChatQrResponse extends WeChatQrResponse {
  @override
  final String qrUrl;
  @override
  final String state;

  factory _$WeChatQrResponse([
    void Function(WeChatQrResponseBuilder)? updates,
  ]) => (WeChatQrResponseBuilder()..update(updates))._build();

  _$WeChatQrResponse._({required this.qrUrl, required this.state}) : super._();
  @override
  WeChatQrResponse rebuild(void Function(WeChatQrResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  WeChatQrResponseBuilder toBuilder() =>
      WeChatQrResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeChatQrResponse &&
        qrUrl == other.qrUrl &&
        state == other.state;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, qrUrl.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeChatQrResponse')
          ..add('qrUrl', qrUrl)
          ..add('state', state))
        .toString();
  }
}

class WeChatQrResponseBuilder
    implements Builder<WeChatQrResponse, WeChatQrResponseBuilder> {
  _$WeChatQrResponse? _$v;

  String? _qrUrl;
  String? get qrUrl => _$this._qrUrl;
  set qrUrl(String? qrUrl) => _$this._qrUrl = qrUrl;

  String? _state;
  String? get state => _$this._state;
  set state(String? state) => _$this._state = state;

  WeChatQrResponseBuilder() {
    WeChatQrResponse._defaults(this);
  }

  WeChatQrResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _qrUrl = $v.qrUrl;
      _state = $v.state;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeChatQrResponse other) {
    _$v = other as _$WeChatQrResponse;
  }

  @override
  void update(void Function(WeChatQrResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeChatQrResponse build() => _build();

  _$WeChatQrResponse _build() {
    final _$result =
        _$v ??
        _$WeChatQrResponse._(
          qrUrl: BuiltValueNullFieldError.checkNotNull(
            qrUrl,
            r'WeChatQrResponse',
            'qrUrl',
          ),
          state: BuiltValueNullFieldError.checkNotNull(
            state,
            r'WeChatQrResponse',
            'state',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
