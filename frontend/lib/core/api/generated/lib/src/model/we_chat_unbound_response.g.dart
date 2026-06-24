// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'we_chat_unbound_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeChatUnboundResponse extends WeChatUnboundResponse {
  @override
  final String tempToken;
  @override
  final String? nextPath;
  @override
  final String? status;

  factory _$WeChatUnboundResponse([
    void Function(WeChatUnboundResponseBuilder)? updates,
  ]) => (WeChatUnboundResponseBuilder()..update(updates))._build();

  _$WeChatUnboundResponse._({
    required this.tempToken,
    this.nextPath,
    this.status,
  }) : super._();
  @override
  WeChatUnboundResponse rebuild(
    void Function(WeChatUnboundResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WeChatUnboundResponseBuilder toBuilder() =>
      WeChatUnboundResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeChatUnboundResponse &&
        tempToken == other.tempToken &&
        nextPath == other.nextPath &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, tempToken.hashCode);
    _$hash = $jc(_$hash, nextPath.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeChatUnboundResponse')
          ..add('tempToken', tempToken)
          ..add('nextPath', nextPath)
          ..add('status', status))
        .toString();
  }
}

class WeChatUnboundResponseBuilder
    implements Builder<WeChatUnboundResponse, WeChatUnboundResponseBuilder> {
  _$WeChatUnboundResponse? _$v;

  String? _tempToken;
  String? get tempToken => _$this._tempToken;
  set tempToken(String? tempToken) => _$this._tempToken = tempToken;

  String? _nextPath;
  String? get nextPath => _$this._nextPath;
  set nextPath(String? nextPath) => _$this._nextPath = nextPath;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  WeChatUnboundResponseBuilder() {
    WeChatUnboundResponse._defaults(this);
  }

  WeChatUnboundResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _tempToken = $v.tempToken;
      _nextPath = $v.nextPath;
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeChatUnboundResponse other) {
    _$v = other as _$WeChatUnboundResponse;
  }

  @override
  void update(void Function(WeChatUnboundResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeChatUnboundResponse build() => _build();

  _$WeChatUnboundResponse _build() {
    final _$result =
        _$v ??
        _$WeChatUnboundResponse._(
          tempToken: BuiltValueNullFieldError.checkNotNull(
            tempToken,
            r'WeChatUnboundResponse',
            'tempToken',
          ),
          nextPath: nextPath,
          status: status,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
