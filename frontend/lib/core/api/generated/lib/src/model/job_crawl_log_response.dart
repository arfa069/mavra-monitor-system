//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_crawl_log_response.g.dart';

/// Schema for job crawl log record.
///
/// Properties:
/// * [id] 
/// * [scrapedAt] 
/// * [searchConfigId] 
/// * [status] 
/// * [errorMessage] 
/// * [newJobsCount] 
/// * [totalJobsCount] 
@BuiltValue()
abstract class JobCrawlLogResponse implements Built<JobCrawlLogResponse, JobCrawlLogResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'scraped_at')
  DateTime get scrapedAt;

  @BuiltValueField(wireName: r'search_config_id')
  int get searchConfigId;

  @BuiltValueField(wireName: r'status')
  String get status;

  @BuiltValueField(wireName: r'error_message')
  String? get errorMessage;

  @BuiltValueField(wireName: r'new_jobs_count')
  int? get newJobsCount;

  @BuiltValueField(wireName: r'total_jobs_count')
  int? get totalJobsCount;

  JobCrawlLogResponse._();

  factory JobCrawlLogResponse([void updates(JobCrawlLogResponseBuilder b)]) = _$JobCrawlLogResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobCrawlLogResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobCrawlLogResponse> get serializer => _$JobCrawlLogResponseSerializer();
}

class _$JobCrawlLogResponseSerializer implements PrimitiveSerializer<JobCrawlLogResponse> {
  @override
  final Iterable<Type> types = const [JobCrawlLogResponse, _$JobCrawlLogResponse];

  @override
  final String wireName = r'JobCrawlLogResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobCrawlLogResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'scraped_at';
    yield serializers.serialize(
      object.scrapedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'search_config_id';
    yield serializers.serialize(
      object.searchConfigId,
      specifiedType: const FullType(int),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(String),
    );
    if (object.errorMessage != null) {
      yield r'error_message';
      yield serializers.serialize(
        object.errorMessage,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.newJobsCount != null) {
      yield r'new_jobs_count';
      yield serializers.serialize(
        object.newJobsCount,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.totalJobsCount != null) {
      yield r'total_jobs_count';
      yield serializers.serialize(
        object.totalJobsCount,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobCrawlLogResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobCrawlLogResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'scraped_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scrapedAt = valueDes;
          break;
        case r'search_config_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.searchConfigId = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.status = valueDes;
          break;
        case r'error_message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.errorMessage = valueDes;
          break;
        case r'new_jobs_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.newJobsCount = valueDes;
          break;
        case r'total_jobs_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.totalJobsCount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobCrawlLogResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobCrawlLogResponseBuilder();
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

