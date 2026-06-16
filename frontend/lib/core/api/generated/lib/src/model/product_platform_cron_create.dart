//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_platform_cron_create.g.dart';

/// Create per-platform cron config.
///
/// Properties:
/// * [platform] - 平台
/// * [cronExpression] - 5段 crontab 表达式，null 表示不定时
/// * [cronTimezone] - 时区
@BuiltValue()
abstract class ProductPlatformCronCreate implements Built<ProductPlatformCronCreate, ProductPlatformCronCreateBuilder> {
  /// 平台
  @BuiltValueField(wireName: r'platform')
  String get platform;

  /// 5段 crontab 表达式，null 表示不定时
  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  /// 时区
  @BuiltValueField(wireName: r'cron_timezone')
  String? get cronTimezone;

  ProductPlatformCronCreate._();

  factory ProductPlatformCronCreate([void updates(ProductPlatformCronCreateBuilder b)]) = _$ProductPlatformCronCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductPlatformCronCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductPlatformCronCreate> get serializer => _$ProductPlatformCronCreateSerializer();
}

class _$ProductPlatformCronCreateSerializer implements PrimitiveSerializer<ProductPlatformCronCreate> {
  @override
  final Iterable<Type> types = const [ProductPlatformCronCreate, _$ProductPlatformCronCreate];

  @override
  final String wireName = r'ProductPlatformCronCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductPlatformCronCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(String),
    );
    if (object.cronExpression != null) {
      yield r'cron_expression';
      yield serializers.serialize(
        object.cronExpression,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.cronTimezone != null) {
      yield r'cron_timezone';
      yield serializers.serialize(
        object.cronTimezone,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductPlatformCronCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductPlatformCronCreateBuilder result,
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
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cronTimezone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductPlatformCronCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductPlatformCronCreateBuilder();
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

