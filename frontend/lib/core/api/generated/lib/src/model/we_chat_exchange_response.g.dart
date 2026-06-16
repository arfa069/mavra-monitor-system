// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'we_chat_exchange_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$WeChatExchangeResponse extends WeChatExchangeResponse {
  @override
  final String status;
  @override
  final AuthSessionResponse? session;
  @override
  final WeChatUnboundResponse? unbound;

  factory _$WeChatExchangeResponse([
    void Function(WeChatExchangeResponseBuilder)? updates,
  ]) => (WeChatExchangeResponseBuilder()..update(updates))._build();

  _$WeChatExchangeResponse._({required this.status, this.session, this.unbound})
    : super._();
  @override
  WeChatExchangeResponse rebuild(
    void Function(WeChatExchangeResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  WeChatExchangeResponseBuilder toBuilder() =>
      WeChatExchangeResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is WeChatExchangeResponse &&
        status == other.status &&
        session == other.session &&
        unbound == other.unbound;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, session.hashCode);
    _$hash = $jc(_$hash, unbound.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'WeChatExchangeResponse')
          ..add('status', status)
          ..add('session', session)
          ..add('unbound', unbound))
        .toString();
  }
}

class WeChatExchangeResponseBuilder
    implements Builder<WeChatExchangeResponse, WeChatExchangeResponseBuilder> {
  _$WeChatExchangeResponse? _$v;

  String? _status;
  String? get status => _$this._status;
  set status(String? status) => _$this._status = status;

  AuthSessionResponseBuilder? _session;
  AuthSessionResponseBuilder get session =>
      _$this._session ??= AuthSessionResponseBuilder();
  set session(AuthSessionResponseBuilder? session) => _$this._session = session;

  WeChatUnboundResponseBuilder? _unbound;
  WeChatUnboundResponseBuilder get unbound =>
      _$this._unbound ??= WeChatUnboundResponseBuilder();
  set unbound(WeChatUnboundResponseBuilder? unbound) =>
      _$this._unbound = unbound;

  WeChatExchangeResponseBuilder() {
    WeChatExchangeResponse._defaults(this);
  }

  WeChatExchangeResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _status = $v.status;
      _session = $v.session?.toBuilder();
      _unbound = $v.unbound?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(WeChatExchangeResponse other) {
    _$v = other as _$WeChatExchangeResponse;
  }

  @override
  void update(void Function(WeChatExchangeResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  WeChatExchangeResponse build() => _build();

  _$WeChatExchangeResponse _build() {
    _$WeChatExchangeResponse _$result;
    try {
      _$result =
          _$v ??
          _$WeChatExchangeResponse._(
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'WeChatExchangeResponse',
              'status',
            ),
            session: _session?.build(),
            unbound: _unbound?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'session';
        _session?.build();
        _$failedField = 'unbound';
        _unbound?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'WeChatExchangeResponse',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
