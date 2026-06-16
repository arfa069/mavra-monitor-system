//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/product_batch_create_item.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_batch_create.g.dart';

/// Batch create products.
///
/// Properties:
/// * [items] 
@BuiltValue()
abstract class ProductBatchCreate implements Built<ProductBatchCreate, ProductBatchCreateBuilder> {
  @BuiltValueField(wireName: r'items')
  BuiltList<ProductBatchCreateItem> get items;

  ProductBatchCreate._();

  factory ProductBatchCreate([void updates(ProductBatchCreateBuilder b)]) = _$ProductBatchCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductBatchCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductBatchCreate> get serializer => _$ProductBatchCreateSerializer();
}

class _$ProductBatchCreateSerializer implements PrimitiveSerializer<ProductBatchCreate> {
  @override
  final Iterable<Type> types = const [ProductBatchCreate, _$ProductBatchCreate];

  @override
  final String wireName = r'ProductBatchCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductBatchCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(ProductBatchCreateItem)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductBatchCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductBatchCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ProductBatchCreateItem)]),
          ) as BuiltList<ProductBatchCreateItem>;
          result.items.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductBatchCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductBatchCreateBuilder();
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

