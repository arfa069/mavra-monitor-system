//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_search_config_create.g.dart';

/// Schema for creating a job search config.
///
/// Properties:
/// * [name] 
/// * [url] 
/// * [active] 
/// * [cityCode] 
/// * [cronExpression] 
/// * [cronTimezone] 
/// * [deactivationThreshold] 
/// * [education] 
/// * [enableMatchAnalysis] 
/// * [experience] 
/// * [keyword] 
/// * [notifyOnNew] 
/// * [platform] 
/// * [profileKey] 
/// * [salaryMax] 
/// * [salaryMin] 
@BuiltValue()
abstract class JobSearchConfigCreate implements Built<JobSearchConfigCreate, JobSearchConfigCreateBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'url')
  String get url;

  @BuiltValueField(wireName: r'active')
  bool? get active;

  @BuiltValueField(wireName: r'city_code')
  String? get cityCode;

  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  @BuiltValueField(wireName: r'cron_timezone')
  String? get cronTimezone;

  @BuiltValueField(wireName: r'deactivation_threshold')
  int? get deactivationThreshold;

  @BuiltValueField(wireName: r'education')
  String? get education;

  @BuiltValueField(wireName: r'enable_match_analysis')
  bool? get enableMatchAnalysis;

  @BuiltValueField(wireName: r'experience')
  String? get experience;

  @BuiltValueField(wireName: r'keyword')
  String? get keyword;

  @BuiltValueField(wireName: r'notify_on_new')
  bool? get notifyOnNew;

  @BuiltValueField(wireName: r'platform')
  JobSearchConfigCreatePlatformEnum? get platform;
  // enum platformEnum {  boss,  51job,  liepin,  };

  @BuiltValueField(wireName: r'profile_key')
  String? get profileKey;

  @BuiltValueField(wireName: r'salary_max')
  int? get salaryMax;

  @BuiltValueField(wireName: r'salary_min')
  int? get salaryMin;

  JobSearchConfigCreate._();

  factory JobSearchConfigCreate([void updates(JobSearchConfigCreateBuilder b)]) = _$JobSearchConfigCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobSearchConfigCreateBuilder b) => b
      ..active = true
      ..deactivationThreshold = 3
      ..enableMatchAnalysis = false
      ..notifyOnNew = true
      ..platform = JobSearchConfigCreatePlatformEnum.valueOf('boss')
      ..profileKey = 'default';

  @BuiltValueSerializer(custom: true)
  static Serializer<JobSearchConfigCreate> get serializer => _$JobSearchConfigCreateSerializer();
}

class _$JobSearchConfigCreateSerializer implements PrimitiveSerializer<JobSearchConfigCreate> {
  @override
  final Iterable<Type> types = const [JobSearchConfigCreate, _$JobSearchConfigCreate];

  @override
  final String wireName = r'JobSearchConfigCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobSearchConfigCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
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
    if (object.cityCode != null) {
      yield r'city_code';
      yield serializers.serialize(
        object.cityCode,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.cronExpression != null) {
      yield r'cron_expression';
      yield serializers.serialize(
        object.cronExpression,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.cronTimezone != null) {
      yield r'cron_timezone';
      yield serializers.serialize(
        object.cronTimezone,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.deactivationThreshold != null) {
      yield r'deactivation_threshold';
      yield serializers.serialize(
        object.deactivationThreshold,
        specifiedType: const FullType(int),
      );
    }
    if (object.education != null) {
      yield r'education';
      yield serializers.serialize(
        object.education,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.enableMatchAnalysis != null) {
      yield r'enable_match_analysis';
      yield serializers.serialize(
        object.enableMatchAnalysis,
        specifiedType: const FullType(bool),
      );
    }
    if (object.experience != null) {
      yield r'experience';
      yield serializers.serialize(
        object.experience,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.keyword != null) {
      yield r'keyword';
      yield serializers.serialize(
        object.keyword,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.notifyOnNew != null) {
      yield r'notify_on_new';
      yield serializers.serialize(
        object.notifyOnNew,
        specifiedType: const FullType(bool),
      );
    }
    if (object.platform != null) {
      yield r'platform';
      yield serializers.serialize(
        object.platform,
        specifiedType: const FullType(JobSearchConfigCreatePlatformEnum),
      );
    }
    if (object.profileKey != null) {
      yield r'profile_key';
      yield serializers.serialize(
        object.profileKey,
        specifiedType: const FullType(String),
      );
    }
    if (object.salaryMax != null) {
      yield r'salary_max';
      yield serializers.serialize(
        object.salaryMax,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.salaryMin != null) {
      yield r'salary_min';
      yield serializers.serialize(
        object.salaryMin,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobSearchConfigCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobSearchConfigCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
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
        case r'city_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cityCode = valueDes;
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
        case r'keyword':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.keyword = valueDes;
          break;
        case r'notify_on_new':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.notifyOnNew = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JobSearchConfigCreatePlatformEnum),
          ) as JobSearchConfigCreatePlatformEnum;
          result.platform = valueDes;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobSearchConfigCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobSearchConfigCreateBuilder();
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

class JobSearchConfigCreatePlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'boss')
  static const JobSearchConfigCreatePlatformEnum boss = _$jobSearchConfigCreatePlatformEnum_boss;
  @BuiltValueEnumConst(wireName: r'51job')
  static const JobSearchConfigCreatePlatformEnum n51job = _$jobSearchConfigCreatePlatformEnum_n51job;
  @BuiltValueEnumConst(wireName: r'liepin')
  static const JobSearchConfigCreatePlatformEnum liepin = _$jobSearchConfigCreatePlatformEnum_liepin;

  static Serializer<JobSearchConfigCreatePlatformEnum> get serializer => _$jobSearchConfigCreatePlatformEnumSerializer;

  const JobSearchConfigCreatePlatformEnum._(String name): super(name);

  static BuiltSet<JobSearchConfigCreatePlatformEnum> get values => _$jobSearchConfigCreatePlatformEnumValues;
  static JobSearchConfigCreatePlatformEnum valueOf(String name) => _$jobSearchConfigCreatePlatformEnumValueOf(name);
}

