//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'app_schemas_auth_message_response.g.dart';

/// Generic message response.
///
/// Properties:
/// * [message] 
@BuiltValue()
abstract class AppSchemasAuthMessageResponse implements Built<AppSchemasAuthMessageResponse, AppSchemasAuthMessageResponseBuilder> {
  @BuiltValueField(wireName: r'message')
  String get message;

  AppSchemasAuthMessageResponse._();

  factory AppSchemasAuthMessageResponse([void updates(AppSchemasAuthMessageResponseBuilder b)]) = _$AppSchemasAuthMessageResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppSchemasAuthMessageResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppSchemasAuthMessageResponse> get serializer => _$AppSchemasAuthMessageResponseSerializer();
}

class _$AppSchemasAuthMessageResponseSerializer implements PrimitiveSerializer<AppSchemasAuthMessageResponse> {
  @override
  final Iterable<Type> types = const [AppSchemasAuthMessageResponse, _$AppSchemasAuthMessageResponse];

  @override
  final String wireName = r'AppSchemasAuthMessageResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppSchemasAuthMessageResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AppSchemasAuthMessageResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppSchemasAuthMessageResponseBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AppSchemasAuthMessageResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppSchemasAuthMessageResponseBuilder();
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

