//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_batch_create_item.g.dart';

/// Single item for batch create.
///
/// Properties:
/// * [url] - Product URL
/// * [platform] - Platform (auto-detected if omitted)
/// * [title] 
@BuiltValue()
abstract class ProductBatchCreateItem implements Built<ProductBatchCreateItem, ProductBatchCreateItemBuilder> {
  /// Product URL
  @BuiltValueField(wireName: r'url')
  String get url;

  /// Platform (auto-detected if omitted)
  @BuiltValueField(wireName: r'platform')
  String? get platform;

  @BuiltValueField(wireName: r'title')
  String? get title;

  ProductBatchCreateItem._();

  factory ProductBatchCreateItem([void updates(ProductBatchCreateItemBuilder b)]) = _$ProductBatchCreateItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductBatchCreateItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductBatchCreateItem> get serializer => _$ProductBatchCreateItemSerializer();
}

class _$ProductBatchCreateItemSerializer implements PrimitiveSerializer<ProductBatchCreateItem> {
  @override
  final Iterable<Type> types = const [ProductBatchCreateItem, _$ProductBatchCreateItem];

  @override
  final String wireName = r'ProductBatchCreateItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductBatchCreateItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
    if (object.platform != null) {
      yield r'platform';
      yield serializers.serialize(
        object.platform,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductBatchCreateItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductBatchCreateItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.platform = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductBatchCreateItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductBatchCreateItemBuilder();
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

