//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_platform_profile_binding_response.g.dart';

/// Product platform to crawl profile binding.
///
/// Properties:
/// * [platform] 
/// * [createdAt] 
/// * [profileKey] 
/// * [profileLastError] 
/// * [profileStatus] 
/// * [updatedAt] 
@BuiltValue()
abstract class ProductPlatformProfileBindingResponse implements Built<ProductPlatformProfileBindingResponse, ProductPlatformProfileBindingResponseBuilder> {
  @BuiltValueField(wireName: r'platform')
  String get platform;

  @BuiltValueField(wireName: r'created_at')
  DateTime? get createdAt;

  @BuiltValueField(wireName: r'profile_key')
  String? get profileKey;

  @BuiltValueField(wireName: r'profile_last_error')
  String? get profileLastError;

  @BuiltValueField(wireName: r'profile_status')
  String? get profileStatus;

  @BuiltValueField(wireName: r'updated_at')
  DateTime? get updatedAt;

  ProductPlatformProfileBindingResponse._();

  factory ProductPlatformProfileBindingResponse([void updates(ProductPlatformProfileBindingResponseBuilder b)]) = _$ProductPlatformProfileBindingResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductPlatformProfileBindingResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductPlatformProfileBindingResponse> get serializer => _$ProductPlatformProfileBindingResponseSerializer();
}

class _$ProductPlatformProfileBindingResponseSerializer implements PrimitiveSerializer<ProductPlatformProfileBindingResponse> {
  @override
  final Iterable<Type> types = const [ProductPlatformProfileBindingResponse, _$ProductPlatformProfileBindingResponse];

  @override
  final String wireName = r'ProductPlatformProfileBindingResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductPlatformProfileBindingResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(String),
    );
    if (object.createdAt != null) {
      yield r'created_at';
      yield serializers.serialize(
        object.createdAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.profileKey != null) {
      yield r'profile_key';
      yield serializers.serialize(
        object.profileKey,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.profileLastError != null) {
      yield r'profile_last_error';
      yield serializers.serialize(
        object.profileLastError,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.profileStatus != null) {
      yield r'profile_status';
      yield serializers.serialize(
        object.profileStatus,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.updatedAt != null) {
      yield r'updated_at';
      yield serializers.serialize(
        object.updatedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductPlatformProfileBindingResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductPlatformProfileBindingResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.platform = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.createdAt = valueDes;
          break;
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.profileKey = valueDes;
          break;
        case r'profile_last_error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.profileLastError = valueDes;
          break;
        case r'profile_status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.profileStatus = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductPlatformProfileBindingResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductPlatformProfileBindingResponseBuilder();
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

