//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_batch_update.g.dart';

/// Batch update products.
///
/// Properties:
/// * [ids] 
/// * [active] 
@BuiltValue()
abstract class ProductBatchUpdate implements Built<ProductBatchUpdate, ProductBatchUpdateBuilder> {
  @BuiltValueField(wireName: r'ids')
  BuiltList<int> get ids;

  @BuiltValueField(wireName: r'active')
  bool? get active;

  ProductBatchUpdate._();

  factory ProductBatchUpdate([void updates(ProductBatchUpdateBuilder b)]) = _$ProductBatchUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductBatchUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductBatchUpdate> get serializer => _$ProductBatchUpdateSerializer();
}

class _$ProductBatchUpdateSerializer implements PrimitiveSerializer<ProductBatchUpdate> {
  @override
  final Iterable<Type> types = const [ProductBatchUpdate, _$ProductBatchUpdate];

  @override
  final String wireName = r'ProductBatchUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductBatchUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ids';
    yield serializers.serialize(
      object.ids,
      specifiedType: const FullType(BuiltList, [FullType(int)]),
    );
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType.nullable(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductBatchUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductBatchUpdateBuilder result,
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
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.active = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductBatchUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductBatchUpdateBuilder();
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

