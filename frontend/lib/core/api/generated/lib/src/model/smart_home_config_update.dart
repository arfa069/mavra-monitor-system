//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_config_update.g.dart';

/// SmartHomeConfigUpdate
///
/// Properties:
/// * [baseUrl] 
/// * [enabled] 
/// * [token] 
@BuiltValue()
abstract class SmartHomeConfigUpdate implements Built<SmartHomeConfigUpdate, SmartHomeConfigUpdateBuilder> {
  @BuiltValueField(wireName: r'base_url')
  String get baseUrl;

  @BuiltValueField(wireName: r'enabled')
  bool? get enabled;

  @BuiltValueField(wireName: r'token')
  String? get token;

  SmartHomeConfigUpdate._();

  factory SmartHomeConfigUpdate([void updates(SmartHomeConfigUpdateBuilder b)]) = _$SmartHomeConfigUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeConfigUpdateBuilder b) => b
      ..enabled = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeConfigUpdate> get serializer => _$SmartHomeConfigUpdateSerializer();
}

class _$SmartHomeConfigUpdateSerializer implements PrimitiveSerializer<SmartHomeConfigUpdate> {
  @override
  final Iterable<Type> types = const [SmartHomeConfigUpdate, _$SmartHomeConfigUpdate];

  @override
  final String wireName = r'SmartHomeConfigUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeConfigUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'base_url';
    yield serializers.serialize(
      object.baseUrl,
      specifiedType: const FullType(String),
    );
    if (object.enabled != null) {
      yield r'enabled';
      yield serializers.serialize(
        object.enabled,
        specifiedType: const FullType(bool),
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
    SmartHomeConfigUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeConfigUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'base_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.baseUrl = valueDes;
          break;
        case r'enabled':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enabled = valueDes;
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
  SmartHomeConfigUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeConfigUpdateBuilder();
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

