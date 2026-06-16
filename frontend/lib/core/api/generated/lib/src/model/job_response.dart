//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_response.g.dart';

/// Schema for job response.
///
/// Properties:
/// * [address] 
/// * [company] 
/// * [companyId] 
/// * [description] 
/// * [education] 
/// * [experience] 
/// * [firstSeenAt] 
/// * [id] 
/// * [isActive] 
/// * [jobId] 
/// * [lastUpdatedAt] 
/// * [location] 
/// * [platform] 
/// * [salary] 
/// * [salaryMax] 
/// * [salaryMin] 
/// * [searchConfigId] 
/// * [title] 
/// * [url] 
/// * [applyRecommendation] 
@BuiltValue()
abstract class JobResponse implements Built<JobResponse, JobResponseBuilder> {
  @BuiltValueField(wireName: r'address')
  String? get address;

  @BuiltValueField(wireName: r'company')
  String? get company;

  @BuiltValueField(wireName: r'company_id')
  String? get companyId;

  @BuiltValueField(wireName: r'description')
  String? get description;

  @BuiltValueField(wireName: r'education')
  String? get education;

  @BuiltValueField(wireName: r'experience')
  String? get experience;

  @BuiltValueField(wireName: r'first_seen_at')
  DateTime get firstSeenAt;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'is_active')
  bool get isActive;

  @BuiltValueField(wireName: r'job_id')
  String get jobId;

  @BuiltValueField(wireName: r'last_updated_at')
  DateTime get lastUpdatedAt;

  @BuiltValueField(wireName: r'location')
  String? get location;

  @BuiltValueField(wireName: r'platform')
  JobResponsePlatformEnum get platform;
  // enum platformEnum {  boss,  51job,  liepin,  };

  @BuiltValueField(wireName: r'salary')
  String? get salary;

  @BuiltValueField(wireName: r'salary_max')
  int? get salaryMax;

  @BuiltValueField(wireName: r'salary_min')
  int? get salaryMin;

  @BuiltValueField(wireName: r'search_config_id')
  int get searchConfigId;

  @BuiltValueField(wireName: r'title')
  String? get title;

  @BuiltValueField(wireName: r'url')
  String? get url;

  @BuiltValueField(wireName: r'apply_recommendation')
  String? get applyRecommendation;

  JobResponse._();

  factory JobResponse([void updates(JobResponseBuilder b)]) = _$JobResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobResponse> get serializer => _$JobResponseSerializer();
}

class _$JobResponseSerializer implements PrimitiveSerializer<JobResponse> {
  @override
  final Iterable<Type> types = const [JobResponse, _$JobResponse];

  @override
  final String wireName = r'JobResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'address';
    yield object.address == null ? null : serializers.serialize(
      object.address,
      specifiedType: const FullType.nullable(String),
    );
    yield r'company';
    yield object.company == null ? null : serializers.serialize(
      object.company,
      specifiedType: const FullType.nullable(String),
    );
    yield r'company_id';
    yield object.companyId == null ? null : serializers.serialize(
      object.companyId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'description';
    yield object.description == null ? null : serializers.serialize(
      object.description,
      specifiedType: const FullType.nullable(String),
    );
    yield r'education';
    yield object.education == null ? null : serializers.serialize(
      object.education,
      specifiedType: const FullType.nullable(String),
    );
    yield r'experience';
    yield object.experience == null ? null : serializers.serialize(
      object.experience,
      specifiedType: const FullType.nullable(String),
    );
    yield r'first_seen_at';
    yield serializers.serialize(
      object.firstSeenAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'is_active';
    yield serializers.serialize(
      object.isActive,
      specifiedType: const FullType(bool),
    );
    yield r'job_id';
    yield serializers.serialize(
      object.jobId,
      specifiedType: const FullType(String),
    );
    yield r'last_updated_at';
    yield serializers.serialize(
      object.lastUpdatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'location';
    yield object.location == null ? null : serializers.serialize(
      object.location,
      specifiedType: const FullType.nullable(String),
    );
    yield r'platform';
    yield serializers.serialize(
      object.platform,
      specifiedType: const FullType(JobResponsePlatformEnum),
    );
    yield r'salary';
    yield object.salary == null ? null : serializers.serialize(
      object.salary,
      specifiedType: const FullType.nullable(String),
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
    yield r'search_config_id';
    yield serializers.serialize(
      object.searchConfigId,
      specifiedType: const FullType(int),
    );
    yield r'title';
    yield object.title == null ? null : serializers.serialize(
      object.title,
      specifiedType: const FullType.nullable(String),
    );
    yield r'url';
    yield object.url == null ? null : serializers.serialize(
      object.url,
      specifiedType: const FullType.nullable(String),
    );
    if (object.applyRecommendation != null) {
      yield r'apply_recommendation';
      yield serializers.serialize(
        object.applyRecommendation,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'address':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.address = valueDes;
          break;
        case r'company':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.company = valueDes;
          break;
        case r'company_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.companyId = valueDes;
          break;
        case r'description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.description = valueDes;
          break;
        case r'education':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.education = valueDes;
          break;
        case r'experience':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.experience = valueDes;
          break;
        case r'first_seen_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.firstSeenAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'is_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        case r'job_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jobId = valueDes;
          break;
        case r'last_updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.lastUpdatedAt = valueDes;
          break;
        case r'location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.location = valueDes;
          break;
        case r'platform':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JobResponsePlatformEnum),
          ) as JobResponsePlatformEnum;
          result.platform = valueDes;
          break;
        case r'salary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.salary = valueDes;
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
        case r'search_config_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.searchConfigId = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        case r'url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.url = valueDes;
          break;
        case r'apply_recommendation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.applyRecommendation = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobResponseBuilder();
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

class JobResponsePlatformEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'boss')
  static const JobResponsePlatformEnum boss = _$jobResponsePlatformEnum_boss;
  @BuiltValueEnumConst(wireName: r'51job')
  static const JobResponsePlatformEnum n51job = _$jobResponsePlatformEnum_n51job;
  @BuiltValueEnumConst(wireName: r'liepin')
  static const JobResponsePlatformEnum liepin = _$jobResponsePlatformEnum_liepin;

  static Serializer<JobResponsePlatformEnum> get serializer => _$jobResponsePlatformEnumSerializer;

  const JobResponsePlatformEnum._(String name): super(name);

  static BuiltSet<JobResponsePlatformEnum> get values => _$jobResponsePlatformEnumValues;
  static JobResponsePlatformEnum valueOf(String name) => _$jobResponsePlatformEnumValueOf(name);
}

