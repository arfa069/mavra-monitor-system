// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_service_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeServiceResponse extends SmartHomeServiceResponse {
  @override
  final String entityId;
  @override
  final String message;
  @override
  final bool ok;
  @override
  final String service;

  factory _$SmartHomeServiceResponse([
    void Function(SmartHomeServiceResponseBuilder)? updates,
  ]) => (SmartHomeServiceResponseBuilder()..update(updates))._build();

  _$SmartHomeServiceResponse._({
    required this.entityId,
    required this.message,
    required this.ok,
    required this.service,
  }) : super._();
  @override
  SmartHomeServiceResponse rebuild(
    void Function(SmartHomeServiceResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  SmartHomeServiceResponseBuilder toBuilder() =>
      SmartHomeServiceResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeServiceResponse &&
        entityId == other.entityId &&
        message == other.message &&
        ok == other.ok &&
        service == other.service;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entityId.hashCode);
    _$hash = $jc(_$hash, message.hashCode);
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, service.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeServiceResponse')
          ..add('entityId', entityId)
          ..add('message', message)
          ..add('ok', ok)
          ..add('service', service))
        .toString();
  }
}

class SmartHomeServiceResponseBuilder
    implements
        Builder<SmartHomeServiceResponse, SmartHomeServiceResponseBuilder> {
  _$SmartHomeServiceResponse? _$v;

  String? _entityId;
  String? get entityId => _$this._entityId;
  set entityId(String? entityId) => _$this._entityId = entityId;

  String? _message;
  String? get message => _$this._message;
  set message(String? message) => _$this._message = message;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  String? _service;
  String? get service => _$this._service;
  set service(String? service) => _$this._service = service;

  SmartHomeServiceResponseBuilder() {
    SmartHomeServiceResponse._defaults(this);
  }

  SmartHomeServiceResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entityId = $v.entityId;
      _message = $v.message;
      _ok = $v.ok;
      _service = $v.service;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeServiceResponse other) {
    _$v = other as _$SmartHomeServiceResponse;
  }

  @override
  void update(void Function(SmartHomeServiceResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeServiceResponse build() => _build();

  _$SmartHomeServiceResponse _build() {
    final _$result =
        _$v ??
        _$SmartHomeServiceResponse._(
          entityId: BuiltValueNullFieldError.checkNotNull(
            entityId,
            r'SmartHomeServiceResponse',
            'entityId',
          ),
          message: BuiltValueNullFieldError.checkNotNull(
            message,
            r'SmartHomeServiceResponse',
            'message',
          ),
          ok: BuiltValueNullFieldError.checkNotNull(
            ok,
            r'SmartHomeServiceResponse',
            'ok',
          ),
          service: BuiltValueNullFieldError.checkNotNull(
            service,
            r'SmartHomeServiceResponse',
            'service',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
