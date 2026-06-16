// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_info_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ServiceInfoResponseStatusEnum _$serviceInfoResponseStatusEnum_ok =
    const ServiceInfoResponseStatusEnum._('ok');

ServiceInfoResponseStatusEnum _$serviceInfoResponseStatusEnumValueOf(
  String name,
) {
  switch (name) {
    case 'ok':
      return _$serviceInfoResponseStatusEnum_ok;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ServiceInfoResponseStatusEnum>
_$serviceInfoResponseStatusEnumValues = BuiltSet<ServiceInfoResponseStatusEnum>(
  const <ServiceInfoResponseStatusEnum>[_$serviceInfoResponseStatusEnum_ok],
);

Serializer<ServiceInfoResponseStatusEnum>
_$serviceInfoResponseStatusEnumSerializer =
    _$ServiceInfoResponseStatusEnumSerializer();

class _$ServiceInfoResponseStatusEnumSerializer
    implements PrimitiveSerializer<ServiceInfoResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{'ok': 'ok'};
  static const Map<Object, String> _fromWire = const <Object, String>{
    'ok': 'ok',
  };

  @override
  final Iterable<Type> types = const <Type>[ServiceInfoResponseStatusEnum];
  @override
  final String wireName = 'ServiceInfoResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    ServiceInfoResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  ServiceInfoResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => ServiceInfoResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$ServiceInfoResponse extends ServiceInfoResponse {
  @override
  final String docs;
  @override
  final String name;
  @override
  final BuiltList<String> prefixes;
  @override
  final ServiceInfoResponseStatusEnum status;

  factory _$ServiceInfoResponse([
    void Function(ServiceInfoResponseBuilder)? updates,
  ]) => (ServiceInfoResponseBuilder()..update(updates))._build();

  _$ServiceInfoResponse._({
    required this.docs,
    required this.name,
    required this.prefixes,
    required this.status,
  }) : super._();
  @override
  ServiceInfoResponse rebuild(
    void Function(ServiceInfoResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  ServiceInfoResponseBuilder toBuilder() =>
      ServiceInfoResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ServiceInfoResponse &&
        docs == other.docs &&
        name == other.name &&
        prefixes == other.prefixes &&
        status == other.status;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, docs.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, prefixes.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ServiceInfoResponse')
          ..add('docs', docs)
          ..add('name', name)
          ..add('prefixes', prefixes)
          ..add('status', status))
        .toString();
  }
}

class ServiceInfoResponseBuilder
    implements Builder<ServiceInfoResponse, ServiceInfoResponseBuilder> {
  _$ServiceInfoResponse? _$v;

  String? _docs;
  String? get docs => _$this._docs;
  set docs(String? docs) => _$this._docs = docs;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  ListBuilder<String>? _prefixes;
  ListBuilder<String> get prefixes =>
      _$this._prefixes ??= ListBuilder<String>();
  set prefixes(ListBuilder<String>? prefixes) => _$this._prefixes = prefixes;

  ServiceInfoResponseStatusEnum? _status;
  ServiceInfoResponseStatusEnum? get status => _$this._status;
  set status(ServiceInfoResponseStatusEnum? status) => _$this._status = status;

  ServiceInfoResponseBuilder() {
    ServiceInfoResponse._defaults(this);
  }

  ServiceInfoResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _docs = $v.docs;
      _name = $v.name;
      _prefixes = $v.prefixes.toBuilder();
      _status = $v.status;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ServiceInfoResponse other) {
    _$v = other as _$ServiceInfoResponse;
  }

  @override
  void update(void Function(ServiceInfoResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ServiceInfoResponse build() => _build();

  _$ServiceInfoResponse _build() {
    _$ServiceInfoResponse _$result;
    try {
      _$result =
          _$v ??
          _$ServiceInfoResponse._(
            docs: BuiltValueNullFieldError.checkNotNull(
              docs,
              r'ServiceInfoResponse',
              'docs',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'ServiceInfoResponse',
              'name',
            ),
            prefixes: prefixes.build(),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'ServiceInfoResponse',
              'status',
            ),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'prefixes';
        prefixes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'ServiceInfoResponse',
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
