//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_search_config_update.g.dart';

/// Schema for updating a job search config.
///
/// Properties:
/// * [active] 
/// * [cityCode] 
/// * [cronExpression] 
/// * [cronTimezone] 
/// * [deactivationThreshold] 
/// * [education] 
/// * [enableMatchAnalysis] 
/// * [experience] 
/// * [keyword] 
/// * [name] 
/// * [notifyOnNew] 
/// * [platform] 
/// * [profileKey] 
/// * [salaryMax] 
/// * [salaryMin] 
/// * [url] 
@BuiltValue()
abstract class JobSearchConfigUpdate implements Built<JobSearchConfigUpdate, JobSearchConfigUpdateBuilder> {
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

  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'notify_on_new')
  bool? get notifyOnNew;

  @BuiltValueField(wireName: r'platform')
  JobSearchConfigUpdatePlatformEnum? get platform;
  // enum platformEnum {  boss,  51job,  liepin,  };

  @BuiltValueField(wireName: r'profile_key')
  String? get profileKey;

  @BuiltValueField(wireName: r'salary_max')
  int? get salaryMax;

  @BuiltValueField(wireName: r'salary_min')
  int? get salaryMin;

  @BuiltValueField(wireName: r'url')
  String? get url;

  JobSearchConfigUpdate._();

  factory JobSearchConfigUpdate([void updates(JobSearchConfigUpdateBuilder b)]) = _$JobSearchConfigUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobSearchConfigUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobSearchConfigUpdate> get serializer => _$JobSearchConfigUpdateSerializer();
}

class _$JobSearchConfigUpdateSerializer implements PrimitiveSerializer<JobSearchConfigUpdate> {
  @override
  final Iterable<Type> types = const [JobSearchConfigUpdate, _$JobSearchConfigUpdate];

  @override
  final String wireName = r'JobSearchConfigUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobSearchConfigUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType.nullable(bool),
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
        specifiedType: const FullType.nullable(int),
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
        specifiedType: const FullType.nullable(bool),
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
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.notifyOnNew != null) {
      yield r'notify_on_new';
      yield serializers.serialize(
        object.notifyOnNew,
        specifiedType: const FullType.nullable(bool),
      );
    }
    if (object.platform != null) {
      yield r'platform';
      yield serializers.serialize(
        object.platform,
        specifiedType: const FullType.nullable(JobSearchConfigUpdatePlatformEnum),
      );
    }
    if (object.profileKey != null) {
      yield r'profile_key';
      yield serializers.serialize(
        object.profileKey,
        specifiedType: const FullType.nullable(String),
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
    if (object.url != null) {
      yield r'url';
      yield serializers.serialize(
        object.url,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobSearchConfigUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobSearchConfigUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
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
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
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
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
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
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'notify_on_new':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.notifyOnNew = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(JobSearchConfigUpdatePlatformEnum),
          ) as JobSearchConfigUpdatePlatformEnum?;
          if (valueDes == null) continue;
          result.platform = valueDes;
          break;
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.url = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobSearchConfigUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobSearchConfigUpdateBuilder();
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

class JobSearchConfigUpdatePlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'boss')
  static const JobSearchConfigUpdatePlatformEnum boss = _$jobSearchConfigUpdatePlatformEnum_boss;
  @BuiltValueEnumConst(wireName: r'51job')
  static const JobSearchConfigUpdatePlatformEnum n51job = _$jobSearchConfigUpdatePlatformEnum_n51job;
  @BuiltValueEnumConst(wireName: r'liepin')
  static const JobSearchConfigUpdatePlatformEnum liepin = _$jobSearchConfigUpdatePlatformEnum_liepin;

  static Serializer<JobSearchConfigUpdatePlatformEnum> get serializer => _$jobSearchConfigUpdatePlatformEnumSerializer;

  const JobSearchConfigUpdatePlatformEnum._(String name): super(name);

  static BuiltSet<JobSearchConfigUpdatePlatformEnum> get values => _$jobSearchConfigUpdatePlatformEnumValues;
  static JobSearchConfigUpdatePlatformEnum valueOf(String name) => _$jobSearchConfigUpdatePlatformEnumValueOf(name);
}

