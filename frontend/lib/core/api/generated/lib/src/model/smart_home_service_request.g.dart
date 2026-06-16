// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_service_request.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SmartHomeServiceRequest extends SmartHomeServiceRequest {
  @override
  final String entityId;
  @override
  final String service;
  @override
  final BuiltMap<String, JsonObject?>? serviceData;

  factory _$SmartHomeServiceRequest(
          [void Function(SmartHomeServiceRequestBuilder)? updates]) =>
      (SmartHomeServiceRequestBuilder()..update(updates))._build();

  _$SmartHomeServiceRequest._(
      {required this.entityId, required this.service, this.serviceData})
      : super._();
  @override
  SmartHomeServiceRequest rebuild(
          void Function(SmartHomeServiceRequestBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SmartHomeServiceRequestBuilder toBuilder() =>
      SmartHomeServiceRequestBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeServiceRequest &&
        entityId == other.entityId &&
        service == other.service &&
        serviceData == other.serviceData;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, entityId.hashCode);
    _$hash = $jc(_$hash, service.hashCode);
    _$hash = $jc(_$hash, serviceData.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeServiceRequest')
          ..add('entityId', entityId)
          ..add('service', service)
          ..add('serviceData', serviceData))
        .toString();
  }
}

class SmartHomeServiceRequestBuilder
    implements
        Builder<SmartHomeServiceRequest, SmartHomeServiceRequestBuilder> {
  _$SmartHomeServiceRequest? _$v;

  String? _entityId;
  String? get entityId => _$this._entityId;
  set entityId(String? entityId) => _$this._entityId = entityId;

  String? _service;
  String? get service => _$this._service;
  set service(String? service) => _$this._service = service;

  MapBuilder<String, JsonObject?>? _serviceData;
  MapBuilder<String, JsonObject?> get serviceData =>
      _$this._serviceData ??= MapBuilder<String, JsonObject?>();
  set serviceData(MapBuilder<String, JsonObject?>? serviceData) =>
      _$this._serviceData = serviceData;

  SmartHomeServiceRequestBuilder() {
    SmartHomeServiceRequest._defaults(this);
  }

  SmartHomeServiceRequestBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _entityId = $v.entityId;
      _service = $v.service;
      _serviceData = $v.serviceData?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeServiceRequest other) {
    _$v = other as _$SmartHomeServiceRequest;
  }

  @override
  void update(void Function(SmartHomeServiceRequestBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeServiceRequest build() => _build();

  _$SmartHomeServiceRequest _build() {
    _$SmartHomeServiceRequest _$result;
    try {
      _$result = _$v ??
          _$SmartHomeServiceRequest._(
            entityId: BuiltValueNullFieldError.checkNotNull(
                entityId, r'SmartHomeServiceRequest', 'entityId'),
            service: BuiltValueNullFieldError.checkNotNull(
                service, r'SmartHomeServiceRequest', 'service'),
            serviceData: _serviceData?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'serviceData';
        _serviceData?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SmartHomeServiceRequest', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
