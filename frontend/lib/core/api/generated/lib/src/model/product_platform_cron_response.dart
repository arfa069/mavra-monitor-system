//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_platform_cron_response.g.dart';

/// Per-platform cron config for product crawling.
///
/// Properties:
/// * [createdAt] 
/// * [cronExpression] 
/// * [cronTimezone] 
/// * [id] 
/// * [platform] 
/// * [profileKey] 
/// * [updatedAt] 
/// * [userId] 
@BuiltValue()
abstract class ProductPlatformCronResponse implements Built<ProductPlatformCronResponse, ProductPlatformCronResponseBuilder> {
  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  @BuiltValueField(wireName: r'cron_timezone')
  String get cronTimezone;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'platform')
  String get platform;

  @BuiltValueField(wireName: r'profile_key')
  String? get profileKey;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'user_id')
  int get userId;

  ProductPlatformCronResponse._();

  factory ProductPlatformCronResponse([void updates(ProductPlatformCronResponseBuilder b)]) = _$ProductPlatformCronResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductPlatformCronResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductPlatformCronResponse> get serializer => _$ProductPlatformCronResponseSerializer();
}

class _$ProductPlatformCronResponseSerializer implements PrimitiveSerializer<ProductPlatformCronResponse> {
  @override
  final Iterable<Type> types = const [ProductPlatformCronResponse, _$ProductPlatformCronResponse];

  @override
  final String wireName = r'ProductPlatformCronResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductPlatformCronResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'cron_expression';
    yield object.cronExpression == null ? null : serializers.serialize(
      object.cronExpression,
      specifiedType: const FullType.nullable(String),
    );
    yield r'cron_timezone';
    yield serializers.serialize(
      object.cronTimezone,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(String),
    );
    yield r'profile_key';
    yield object.profileKey == null ? null : serializers.serialize(
      object.profileKey,
      specifiedType: const FullType.nullable(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductPlatformCronResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductPlatformCronResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'cron_expression':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cronExpression = valueDes;
          break;
        case r'cron_timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.cronTimezone = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.platform = valueDes;
          break;
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.profileKey = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.userId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductPlatformCronResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductPlatformCronResponseBuilder();
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

