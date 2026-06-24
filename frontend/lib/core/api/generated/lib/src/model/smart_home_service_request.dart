//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_service_request.g.dart';

/// SmartHomeServiceRequest
///
/// Properties:
/// * [entityId] 
/// * [service] 
/// * [serviceData] 
@BuiltValue()
abstract class SmartHomeServiceRequest implements Built<SmartHomeServiceRequest, SmartHomeServiceRequestBuilder> {
  @BuiltValueField(wireName: r'entity_id')
  String get entityId;

  @BuiltValueField(wireName: r'service')
  String get service;

  @BuiltValueField(wireName: r'service_data')
  BuiltMap<String, JsonObject?>? get serviceData;

  SmartHomeServiceRequest._();

  factory SmartHomeServiceRequest([void updates(SmartHomeServiceRequestBuilder b)]) = _$SmartHomeServiceRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeServiceRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeServiceRequest> get serializer => _$SmartHomeServiceRequestSerializer();
}

class _$SmartHomeServiceRequestSerializer implements PrimitiveSerializer<SmartHomeServiceRequest> {
  @override
  final Iterable<Type> types = const [SmartHomeServiceRequest, _$SmartHomeServiceRequest];

  @override
  final String wireName = r'SmartHomeServiceRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeServiceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entity_id';
    yield serializers.serialize(
      object.entityId,
      specifiedType: const FullType(String),
    );
    yield r'service';
    yield serializers.serialize(
      object.service,
      specifiedType: const FullType(String),
    );
    if (object.serviceData != null) {
      yield r'service_data';
      yield serializers.serialize(
        object.serviceData,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeServiceRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeServiceRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'entity_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.entityId = valueDes;
          break;
        case r'service':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.service = valueDes;
          break;
        case r'service_data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.serviceData.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeServiceRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeServiceRequestBuilder();
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

