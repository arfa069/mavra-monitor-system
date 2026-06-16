//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_platform_profile_binding_update.g.dart';

/// Update product platform profile binding.
///
/// Properties:
/// * [profileKey] 
@BuiltValue()
abstract class ProductPlatformProfileBindingUpdate implements Built<ProductPlatformProfileBindingUpdate, ProductPlatformProfileBindingUpdateBuilder> {
  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  ProductPlatformProfileBindingUpdate._();

  factory ProductPlatformProfileBindingUpdate([void updates(ProductPlatformProfileBindingUpdateBuilder b)]) = _$ProductPlatformProfileBindingUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductPlatformProfileBindingUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductPlatformProfileBindingUpdate> get serializer => _$ProductPlatformProfileBindingUpdateSerializer();
}

class _$ProductPlatformProfileBindingUpdateSerializer implements PrimitiveSerializer<ProductPlatformProfileBindingUpdate> {
  @override
  final Iterable<Type> types = const [ProductPlatformProfileBindingUpdate, _$ProductPlatformProfileBindingUpdate];

  @override
  final String wireName = r'ProductPlatformProfileBindingUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductPlatformProfileBindingUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'profile_key';
    yield serializers.serialize(
      object.profileKey,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductPlatformProfileBindingUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductPlatformProfileBindingUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.profileKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductPlatformProfileBindingUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductPlatformProfileBindingUpdateBuilder();
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

