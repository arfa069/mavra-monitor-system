//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_service_response.g.dart';

/// SmartHomeServiceResponse
///
/// Properties:
/// * [entityId] 
/// * [message] 
/// * [ok] 
/// * [service] 
@BuiltValue()
abstract class SmartHomeServiceResponse implements Built<SmartHomeServiceResponse, SmartHomeServiceResponseBuilder> {
  @BuiltValueField(wireName: r'entity_id')
  String get entityId;

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'ok')
  bool get ok;

  @BuiltValueField(wireName: r'service')
  String get service;

  SmartHomeServiceResponse._();

  factory SmartHomeServiceResponse([void updates(SmartHomeServiceResponseBuilder b)]) = _$SmartHomeServiceResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeServiceResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeServiceResponse> get serializer => _$SmartHomeServiceResponseSerializer();
}

class _$SmartHomeServiceResponseSerializer implements PrimitiveSerializer<SmartHomeServiceResponse> {
  @override
  final Iterable<Type> types = const [SmartHomeServiceResponse, _$SmartHomeServiceResponse];

  @override
  final String wireName = r'SmartHomeServiceResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeServiceResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'entity_id';
    yield serializers.serialize(
      object.entityId,
      specifiedType: const FullType(String),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'ok';
    yield serializers.serialize(
      object.ok,
      specifiedType: const FullType(bool),
    );
    yield r'service';
    yield serializers.serialize(
      object.service,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeServiceResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeServiceResponseBuilder result,
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
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'ok':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ok = valueDes;
          break;
        case r'service':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.service = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeServiceResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeServiceResponseBuilder();
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

