//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'cleanup_result_response.g.dart';

/// CleanupResultResponse
///
/// Properties:
/// * [cutoffDate] 
/// * [deletedCrawlLogs] 
/// * [deletedPriceHistory] 
/// * [retentionDays] 
/// * [status] 
@BuiltValue()
abstract class CleanupResultResponse implements Built<CleanupResultResponse, CleanupResultResponseBuilder> {
  @BuiltValueField(wireName: r'cutoff_date')
  DateTime get cutoffDate;

  @BuiltValueField(wireName: r'deleted_crawl_logs')
  int get deletedCrawlLogs;

  @BuiltValueField(wireName: r'deleted_price_history')
  int get deletedPriceHistory;

  @BuiltValueField(wireName: r'retention_days')
  int get retentionDays;

  @BuiltValueField(wireName: r'status')
  CleanupResultResponseStatusEnum get status;
  // enum statusEnum {  completed,  };

  CleanupResultResponse._();

  factory CleanupResultResponse([void updates(CleanupResultResponseBuilder b)]) = _$CleanupResultResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CleanupResultResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CleanupResultResponse> get serializer => _$CleanupResultResponseSerializer();
}

class _$CleanupResultResponseSerializer implements PrimitiveSerializer<CleanupResultResponse> {
  @override
  final Iterable<Type> types = const [CleanupResultResponse, _$CleanupResultResponse];

  @override
  final String wireName = r'CleanupResultResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CleanupResultResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'cutoff_date';
    yield serializers.serialize(
      object.cutoffDate,
      specifiedType: const FullType(DateTime),
    );
    yield r'deleted_crawl_logs';
    yield serializers.serialize(
      object.deletedCrawlLogs,
      specifiedType: const FullType(int),
    );
    yield r'deleted_price_history';
    yield serializers.serialize(
      object.deletedPriceHistory,
      specifiedType: const FullType(int),
    );
    yield r'retention_days';
    yield serializers.serialize(
      object.retentionDays,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(CleanupResultResponseStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CleanupResultResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CleanupResultResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'cutoff_date':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.cutoffDate = valueDes;
          break;
        case r'deleted_crawl_logs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.deletedCrawlLogs = valueDes;
          break;
        case r'deleted_price_history':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.deletedPriceHistory = valueDes;
          break;
        case r'retention_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.retentionDays = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CleanupResultResponseStatusEnum),
          ) as CleanupResultResponseStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CleanupResultResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CleanupResultResponseBuilder();
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

class CleanupResultResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'completed')
  static const CleanupResultResponseStatusEnum completed = _$cleanupResultResponseStatusEnum_completed;

  static Serializer<CleanupResultResponseStatusEnum> get serializer => _$cleanupResultResponseStatusEnumSerializer;

  const CleanupResultResponseStatusEnum._(String name): super(name);

  static BuiltSet<CleanupResultResponseStatusEnum> get values => _$cleanupResultResponseStatusEnumValues;
  static CleanupResultResponseStatusEnum valueOf(String name) => _$cleanupResultResponseStatusEnumValueOf(name);
}

