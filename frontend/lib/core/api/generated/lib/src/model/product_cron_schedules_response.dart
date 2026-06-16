//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/schedule_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'product_cron_schedules_response.g.dart';

/// ProductCronSchedulesResponse
///
/// Properties:
/// * [platforms] 
@BuiltValue()
abstract class ProductCronSchedulesResponse implements Built<ProductCronSchedulesResponse, ProductCronSchedulesResponseBuilder> {
  @BuiltValueField(wireName: r'platforms')
  BuiltMap<String, ScheduleInfo>? get platforms;

  ProductCronSchedulesResponse._();

  factory ProductCronSchedulesResponse([void updates(ProductCronSchedulesResponseBuilder b)]) = _$ProductCronSchedulesResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProductCronSchedulesResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProductCronSchedulesResponse> get serializer => _$ProductCronSchedulesResponseSerializer();
}

class _$ProductCronSchedulesResponseSerializer implements PrimitiveSerializer<ProductCronSchedulesResponse> {
  @override
  final Iterable<Type> types = const [ProductCronSchedulesResponse, _$ProductCronSchedulesResponse];

  @override
  final String wireName = r'ProductCronSchedulesResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProductCronSchedulesResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.platforms != null) {
      yield r'platforms';
      yield serializers.serialize(
        object.platforms,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType(ScheduleInfo)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ProductCronSchedulesResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProductCronSchedulesResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'platforms':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(ScheduleInfo)]),
          ) as BuiltMap<String, ScheduleInfo>;
          result.platforms.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProductCronSchedulesResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProductCronSchedulesResponseBuilder();
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

