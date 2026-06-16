//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_kpi.g.dart';

/// Personal KPI metrics for the current user.
///
/// Properties:
/// * [crawlCountToday] 
/// * [matchCount] 
/// * [newJobsToday] 
/// * [priceDropsToday] 
/// * [totalProducts] 
@BuiltValue()
abstract class UserKPI implements Built<UserKPI, UserKPIBuilder> {
  @BuiltValueField(wireName: r'crawl_count_today')
  int get crawlCountToday;

  @BuiltValueField(wireName: r'match_count')
  int get matchCount;

  @BuiltValueField(wireName: r'new_jobs_today')
  int get newJobsToday;

  @BuiltValueField(wireName: r'price_drops_today')
  int get priceDropsToday;

  @BuiltValueField(wireName: r'total_products')
  int get totalProducts;

  UserKPI._();

  factory UserKPI([void updates(UserKPIBuilder b)]) = _$UserKPI;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserKPIBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserKPI> get serializer => _$UserKPISerializer();
}

class _$UserKPISerializer implements PrimitiveSerializer<UserKPI> {
  @override
  final Iterable<Type> types = const [UserKPI, _$UserKPI];

  @override
  final String wireName = r'UserKPI';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserKPI object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'crawl_count_today';
    yield serializers.serialize(
      object.crawlCountToday,
      specifiedType: const FullType(int),
    );
    yield r'match_count';
    yield serializers.serialize(
      object.matchCount,
      specifiedType: const FullType(int),
    );
    yield r'new_jobs_today';
    yield serializers.serialize(
      object.newJobsToday,
      specifiedType: const FullType(int),
    );
    yield r'price_drops_today';
    yield serializers.serialize(
      object.priceDropsToday,
      specifiedType: const FullType(int),
    );
    yield r'total_products';
    yield serializers.serialize(
      object.totalProducts,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UserKPI object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserKPIBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'crawl_count_today':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.crawlCountToday = valueDes;
          break;
        case r'match_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.matchCount = valueDes;
          break;
        case r'new_jobs_today':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.newJobsToday = valueDes;
          break;
        case r'price_drops_today':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.priceDropsToday = valueDes;
          break;
        case r'total_products':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalProducts = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserKPI deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserKPIBuilder();
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

