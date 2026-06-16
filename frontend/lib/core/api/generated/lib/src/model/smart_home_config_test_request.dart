//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_config_test_request.g.dart';

/// SmartHomeConfigTestRequest
///
/// Properties:
/// * [baseUrl] 
/// * [token] 
@BuiltValue()
abstract class SmartHomeConfigTestRequest implements Built<SmartHomeConfigTestRequest, SmartHomeConfigTestRequestBuilder> {
  @BuiltValueField(wireName: r'base_url')
  String? get baseUrl;

  @BuiltValueField(wireName: r'token')
  String? get token;

  SmartHomeConfigTestRequest._();

  factory SmartHomeConfigTestRequest([void updates(SmartHomeConfigTestRequestBuilder b)]) = _$SmartHomeConfigTestRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeConfigTestRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeConfigTestRequest> get serializer => _$SmartHomeConfigTestRequestSerializer();
}

class _$SmartHomeConfigTestRequestSerializer implements PrimitiveSerializer<SmartHomeConfigTestRequest> {
  @override
  final Iterable<Type> types = const [SmartHomeConfigTestRequest, _$SmartHomeConfigTestRequest];

  @override
  final String wireName = r'SmartHomeConfigTestRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeConfigTestRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.baseUrl != null) {
      yield r'base_url';
      yield serializers.serialize(
        object.baseUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.token != null) {
      yield r'token';
      yield serializers.serialize(
        object.token,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeConfigTestRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeConfigTestRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'base_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.baseUrl = valueDes;
          break;
        case r'token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.token = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeConfigTestRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeConfigTestRequestBuilder();
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

