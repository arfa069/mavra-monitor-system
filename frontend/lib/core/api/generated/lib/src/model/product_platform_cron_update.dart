//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_platform_cron_update.g.dart';

/// Update per-platform cron expression.
///
/// Properties:
/// * [cronExpression] - 5段 crontab 表达式，null 表示不定时
/// * [cronTimezone] - 时区
@BuiltValue()
abstract class ProductPlatformCronUpdate implements Built<ProductPlatformCronUpdate, ProductPlatformCronUpdateBuilder> {
  /// 5段 crontab 表达式，null 表示不定时
  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  /// 时区
  @BuiltValueField(wireName: r'cron_timezone')
  String? get cronTimezone;

  ProductPlatformCronUpdate._();

  factory ProductPlatformCronUpdate([void updates(ProductPlatformCronUpdateBuilder b)]) = _$ProductPlatformCronUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductPlatformCronUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductPlatformCronUpdate> get serializer => _$ProductPlatformCronUpdateSerializer();
}

class _$ProductPlatformCronUpdateSerializer implements PrimitiveSerializer<ProductPlatformCronUpdate> {
  @override
  final Iterable<Type> types = const [ProductPlatformCronUpdate, _$ProductPlatformCronUpdate];

  @override
  final String wireName = r'ProductPlatformCronUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductPlatformCronUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    ProductPlatformCronUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductPlatformCronUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
  ProductPlatformCronUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductPlatformCronUpdateBuilder();
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

