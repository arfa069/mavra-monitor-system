//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_config_test_response.g.dart';

/// SmartHomeConfigTestResponse
///
/// Properties:
/// * [message] 
/// * [ok] 
/// * [homeAssistantVersion] 
@BuiltValue()
abstract class SmartHomeConfigTestResponse implements Built<SmartHomeConfigTestResponse, SmartHomeConfigTestResponseBuilder> {
  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'ok')
  bool get ok;

  @BuiltValueField(wireName: r'home_assistant_version')
  String? get homeAssistantVersion;

  SmartHomeConfigTestResponse._();

  factory SmartHomeConfigTestResponse([void updates(SmartHomeConfigTestResponseBuilder b)]) = _$SmartHomeConfigTestResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeConfigTestResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeConfigTestResponse> get serializer => _$SmartHomeConfigTestResponseSerializer();
}

class _$SmartHomeConfigTestResponseSerializer implements PrimitiveSerializer<SmartHomeConfigTestResponse> {
  @override
  final Iterable<Type> types = const [SmartHomeConfigTestResponse, _$SmartHomeConfigTestResponse];

  @override
  final String wireName = r'SmartHomeConfigTestResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeConfigTestResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    if (object.homeAssistantVersion != null) {
      yield r'home_assistant_version';
      yield serializers.serialize(
        object.homeAssistantVersion,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeConfigTestResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeConfigTestResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'home_assistant_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.homeAssistantVersion = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeConfigTestResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeConfigTestResponseBuilder();
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

