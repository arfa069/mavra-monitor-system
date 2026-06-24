//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_search_config_response.g.dart';

/// Schema for job search config response.
///
/// Properties:
/// * [active] 
/// * [cityCode] 
/// * [createdAt] 
/// * [cronExpression] 
/// * [cronTimezone] 
/// * [deactivationThreshold] 
/// * [education] 
/// * [enableMatchAnalysis] 
/// * [experience] 
/// * [id] 
/// * [keyword] 
/// * [name] 
/// * [notifyOnNew] 
/// * [profileKey] 
/// * [salaryMax] 
/// * [salaryMin] 
/// * [updatedAt] 
/// * [url] 
/// * [userId] 
/// * [platform] 
@BuiltValue()
abstract class JobSearchConfigResponse implements Built<JobSearchConfigResponse, JobSearchConfigResponseBuilder> {
  @BuiltValueField(wireName: r'active')
  bool get active;

  @BuiltValueField(wireName: r'city_code')
  String? get cityCode;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  @BuiltValueField(wireName: r'cron_timezone')
  String? get cronTimezone;

  @BuiltValueField(wireName: r'deactivation_threshold')
  int get deactivationThreshold;

  @BuiltValueField(wireName: r'education')
  String? get education;

  @BuiltValueField(wireName: r'enable_match_analysis')
  bool get enableMatchAnalysis;

  @BuiltValueField(wireName: r'experience')
  String? get experience;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'keyword')
  String? get keyword;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'notify_on_new')
  bool get notifyOnNew;

  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  @BuiltValueField(wireName: r'salary_max')
  int? get salaryMax;

  @BuiltValueField(wireName: r'salary_min')
  int? get salaryMin;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'url')
  String get url;

  @BuiltValueField(wireName: r'user_id')
  int get userId;

  @BuiltValueField(wireName: r'platform')
  JobSearchConfigResponsePlatformEnum? get platform;
  // enum platformEnum {  boss,  51job,  liepin,  };

  JobSearchConfigResponse._();

  factory JobSearchConfigResponse([void updates(JobSearchConfigResponseBuilder b)]) = _$JobSearchConfigResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobSearchConfigResponseBuilder b) => b
      ..platform = JobSearchConfigResponsePlatformEnum.valueOf('boss');

  @BuiltValueSerializer(custom: true)
  static Serializer<JobSearchConfigResponse> get serializer => _$JobSearchConfigResponseSerializer();
}

class _$JobSearchConfigResponseSerializer implements PrimitiveSerializer<JobSearchConfigResponse> {
  @override
  final Iterable<Type> types = const [JobSearchConfigResponse, _$JobSearchConfigResponse];

  @override
  final String wireName = r'JobSearchConfigResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobSearchConfigResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
    yield r'city_code';
    yield object.cityCode == null ? null : serializers.serialize(
      object.cityCode,
      specifiedType: const FullType.nullable(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'cron_expression';
    yield object.cronExpression == null ? null : serializers.serialize(
      object.cronExpression,
      specifiedType: const FullType.nullable(String),
    );
    yield r'cron_timezone';
    yield object.cronTimezone == null ? null : serializers.serialize(
      object.cronTimezone,
      specifiedType: const FullType.nullable(String),
    );
    yield r'deactivation_threshold';
    yield serializers.serialize(
      object.deactivationThreshold,
      specifiedType: const FullType(int),
    );
    yield r'education';
    yield object.education == null ? null : serializers.serialize(
      object.education,
      specifiedType: const FullType.nullable(String),
    );
    yield r'enable_match_analysis';
    yield serializers.serialize(
      object.enableMatchAnalysis,
      specifiedType: const FullType(bool),
    );
    yield r'experience';
    yield object.experience == null ? null : serializers.serialize(
      object.experience,
      specifiedType: const FullType.nullable(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'keyword';
    yield object.keyword == null ? null : serializers.serialize(
      object.keyword,
      specifiedType: const FullType.nullable(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'notify_on_new';
    yield serializers.serialize(
      object.notifyOnNew,
      specifiedType: const FullType(bool),
    );
    yield r'profile_key';
    yield serializers.serialize(
      object.profileKey,
      specifiedType: const FullType(String),
    );
    yield r'salary_max';
    yield object.salaryMax == null ? null : serializers.serialize(
      object.salaryMax,
      specifiedType: const FullType.nullable(int),
    );
    yield r'salary_min';
    yield object.salaryMin == null ? null : serializers.serialize(
      object.salaryMin,
      specifiedType: const FullType.nullable(int),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'url';
    yield serializers.serialize(
      object.url,
      specifiedType: const FullType(String),
    );
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(int),
    );
    if (object.platform != null) {
      yield r'platform';
      yield serializers.serialize(
        object.platform,
        specifiedType: const FullType(JobSearchConfigResponsePlatformEnum),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobSearchConfigResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobSearchConfigResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        case r'city_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cityCode = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
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
        case r'deactivation_threshold':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.deactivationThreshold = valueDes;
          break;
        case r'education':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.education = valueDes;
          break;
        case r'enable_match_analysis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enableMatchAnalysis = valueDes;
          break;
        case r'experience':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.experience = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'keyword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.keyword = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'notify_on_new':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.notifyOnNew = valueDes;
          break;
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.profileKey = valueDes;
          break;
        case r'salary_max':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.salaryMax = valueDes;
          break;
        case r'salary_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.salaryMin = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.url = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.userId = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JobSearchConfigResponsePlatformEnum),
          ) as JobSearchConfigResponsePlatformEnum;
          result.platform = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobSearchConfigResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobSearchConfigResponseBuilder();
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

class JobSearchConfigResponsePlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'boss')
  static const JobSearchConfigResponsePlatformEnum boss = _$jobSearchConfigResponsePlatformEnum_boss;
  @BuiltValueEnumConst(wireName: r'51job')
  static const JobSearchConfigResponsePlatformEnum n51job = _$jobSearchConfigResponsePlatformEnum_n51job;
  @BuiltValueEnumConst(wireName: r'liepin')
  static const JobSearchConfigResponsePlatformEnum liepin = _$jobSearchConfigResponsePlatformEnum_liepin;

  static Serializer<JobSearchConfigResponsePlatformEnum> get serializer => _$jobSearchConfigResponsePlatformEnumSerializer;

  const JobSearchConfigResponsePlatformEnum._(String name): super(name);

  static BuiltSet<JobSearchConfigResponsePlatformEnum> get values => _$jobSearchConfigResponsePlatformEnumValues;
  static JobSearchConfigResponsePlatformEnum valueOf(String name) => _$jobSearchConfigResponsePlatformEnumValueOf(name);
}

