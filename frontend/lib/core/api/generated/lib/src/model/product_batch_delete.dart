//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_batch_delete.g.dart';

/// Batch delete products.
///
/// Properties:
/// * [ids] 
@BuiltValue()
abstract class ProductBatchDelete implements Built<ProductBatchDelete, ProductBatchDeleteBuilder> {
  @BuiltValueField(wireName: r'ids')
  BuiltList<int> get ids;

  ProductBatchDelete._();

  factory ProductBatchDelete([void updates(ProductBatchDeleteBuilder b)]) = _$ProductBatchDelete;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductBatchDeleteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductBatchDelete> get serializer => _$ProductBatchDeleteSerializer();
}

class _$ProductBatchDeleteSerializer implements PrimitiveSerializer<ProductBatchDelete> {
  @override
  final Iterable<Type> types = const [ProductBatchDelete, _$ProductBatchDelete];

  @override
  final String wireName = r'ProductBatchDelete';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductBatchDelete object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ids';
    yield serializers.serialize(
      object.ids,
      specifiedType: const FullType(BuiltList, [FullType(int)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductBatchDelete object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductBatchDeleteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(int)]),
          ) as BuiltList<int>;
          result.ids.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductBatchDelete deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductBatchDeleteBuilder();
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

