//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_create.g.dart';

/// Schema for creating a product to track.
///
/// Properties:
/// * [platform] - Platform: taobao, jd, or amazon
/// * [url] - Product URL
/// * [active] - Whether monitoring is active
/// * [title] - Product title (auto-fetched if not provided)
@BuiltValue()
abstract class ProductCreate implements Built<ProductCreate, ProductCreateBuilder> {
  /// Platform: taobao, jd, or amazon
  @BuiltValueField(wireName: r'platform')
  String get platform;

  /// Product URL
  @BuiltValueField(wireName: r'url')
  String get url;

  /// Whether monitoring is active
  @BuiltValueField(wireName: r'active')
  bool? get active;

  /// Product title (auto-fetched if not provided)
  @BuiltValueField(wireName: r'title')
  String? get title;

  ProductCreate._();

  factory ProductCreate([void updates(ProductCreateBuilder b)]) = _$ProductCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductCreateBuilder b) => b
      ..active = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductCreate> get serializer => _$ProductCreateSerializer();
}

class _$ProductCreateSerializer implements PrimitiveSerializer<ProductCreate> {
  @override
  final Iterable<Type> types = const [ProductCreate, _$ProductCreate];

  @override
  final String wireName = r'ProductCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(String),
    );
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType(bool),
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
    ProductCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductCreateBuilder result,
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
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
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
  ProductCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductCreateBuilder();
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

