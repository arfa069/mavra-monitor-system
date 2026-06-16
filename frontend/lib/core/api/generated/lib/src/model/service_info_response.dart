//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'service_info_response.g.dart';

/// ServiceInfoResponse
///
/// Properties:
/// * [docs] 
/// * [name] 
/// * [prefixes] 
/// * [status] 
@BuiltValue()
abstract class ServiceInfoResponse implements Built<ServiceInfoResponse, ServiceInfoResponseBuilder> {
  @BuiltValueField(wireName: r'docs')
  String get docs;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'prefixes')
  BuiltList<String> get prefixes;

  @BuiltValueField(wireName: r'status')
  ServiceInfoResponseStatusEnum get status;
  // enum statusEnum {  ok,  };

  ServiceInfoResponse._();

  factory ServiceInfoResponse([void updates(ServiceInfoResponseBuilder b)]) = _$ServiceInfoResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ServiceInfoResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ServiceInfoResponse> get serializer => _$ServiceInfoResponseSerializer();
}

class _$ServiceInfoResponseSerializer implements PrimitiveSerializer<ServiceInfoResponse> {
  @override
  final Iterable<Type> types = const [ServiceInfoResponse, _$ServiceInfoResponse];

  @override
  final String wireName = r'ServiceInfoResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ServiceInfoResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'docs';
    yield serializers.serialize(
      object.docs,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'prefixes';
    yield serializers.serialize(
      object.prefixes,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(ServiceInfoResponseStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ServiceInfoResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ServiceInfoResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'docs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.docs = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'prefixes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.prefixes.replace(valueDes);
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ServiceInfoResponseStatusEnum),
          ) as ServiceInfoResponseStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ServiceInfoResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ServiceInfoResponseBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class ServiceInfoResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'ok')
  static const ServiceInfoResponseStatusEnum ok = _$serviceInfoResponseStatusEnum_ok;

  static Serializer<ServiceInfoResponseStatusEnum> get serializer => _$serviceInfoResponseStatusEnumSerializer;

  const ServiceInfoResponseStatusEnum._(String name): super(name);

  static BuiltSet<ServiceInfoResponseStatusEnum> get values => _$serviceInfoResponseStatusEnumValues;
  static ServiceInfoResponseStatusEnum valueOf(String name) => _$serviceInfoResponseStatusEnumValueOf(name);
}

