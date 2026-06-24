//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_result_response.g.dart';

/// MatchResultResponse
///
/// Properties:
/// * [applyRecommendation] 
/// * [createdAt] 
/// * [id] 
/// * [jobId] 
/// * [llmModelUsed] 
/// * [matchReason] 
/// * [matchScore] 
/// * [resumeId] 
/// * [updatedAt] 
/// * [userId] 
/// * [jobCompany] 
/// * [jobDescription] 
/// * [jobLocation] 
/// * [jobSalary] 
/// * [jobTitle] 
/// * [jobUrl] 
@BuiltValue()
abstract class MatchResultResponse implements Built<MatchResultResponse, MatchResultResponseBuilder> {
  @BuiltValueField(wireName: r'apply_recommendation')
  String? get applyRecommendation;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'job_id')
  int get jobId;

  @BuiltValueField(wireName: r'llm_model_used')
  String? get llmModelUsed;

  @BuiltValueField(wireName: r'match_reason')
  String? get matchReason;

  @BuiltValueField(wireName: r'match_score')
  int get matchScore;

  @BuiltValueField(wireName: r'resume_id')
  int get resumeId;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'user_id')
  int get userId;

  @BuiltValueField(wireName: r'job_company')
  String? get jobCompany;

  @BuiltValueField(wireName: r'job_description')
  String? get jobDescription;

  @BuiltValueField(wireName: r'job_location')
  String? get jobLocation;

  @BuiltValueField(wireName: r'job_salary')
  String? get jobSalary;

  @BuiltValueField(wireName: r'job_title')
  String? get jobTitle;

  @BuiltValueField(wireName: r'job_url')
  String? get jobUrl;

  MatchResultResponse._();

  factory MatchResultResponse([void updates(MatchResultResponseBuilder b)]) = _$MatchResultResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchResultResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchResultResponse> get serializer => _$MatchResultResponseSerializer();
}

class _$MatchResultResponseSerializer implements PrimitiveSerializer<MatchResultResponse> {
  @override
  final Iterable<Type> types = const [MatchResultResponse, _$MatchResultResponse];

  @override
  final String wireName = r'MatchResultResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchResultResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'apply_recommendation';
    yield object.applyRecommendation == null ? null : serializers.serialize(
      object.applyRecommendation,
      specifiedType: const FullType.nullable(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'job_id';
    yield serializers.serialize(
      object.jobId,
      specifiedType: const FullType(int),
    );
    yield r'llm_model_used';
    yield object.llmModelUsed == null ? null : serializers.serialize(
      object.llmModelUsed,
      specifiedType: const FullType.nullable(String),
    );
    yield r'match_reason';
    yield object.matchReason == null ? null : serializers.serialize(
      object.matchReason,
      specifiedType: const FullType.nullable(String),
    );
    yield r'match_score';
    yield serializers.serialize(
      object.matchScore,
      specifiedType: const FullType(int),
    );
    yield r'resume_id';
    yield serializers.serialize(
      object.resumeId,
      specifiedType: const FullType(int),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'user_id';
    yield serializers.serialize(
      object.userId,
      specifiedType: const FullType(int),
    );
    if (object.jobCompany != null) {
      yield r'job_company';
      yield serializers.serialize(
        object.jobCompany,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jobDescription != null) {
      yield r'job_description';
      yield serializers.serialize(
        object.jobDescription,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jobLocation != null) {
      yield r'job_location';
      yield serializers.serialize(
        object.jobLocation,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jobSalary != null) {
      yield r'job_salary';
      yield serializers.serialize(
        object.jobSalary,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jobTitle != null) {
      yield r'job_title';
      yield serializers.serialize(
        object.jobTitle,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jobUrl != null) {
      yield r'job_url';
      yield serializers.serialize(
        object.jobUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchResultResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchResultResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'apply_recommendation':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.applyRecommendation = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'job_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.jobId = valueDes;
          break;
        case r'llm_model_used':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.llmModelUsed = valueDes;
          break;
        case r'match_reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.matchReason = valueDes;
          break;
        case r'match_score':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.matchScore = valueDes;
          break;
        case r'resume_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.resumeId = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.userId = valueDes;
          break;
        case r'job_company':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobCompany = valueDes;
          break;
        case r'job_description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobDescription = valueDes;
          break;
        case r'job_location':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobLocation = valueDes;
          break;
        case r'job_salary':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobSalary = valueDes;
          break;
        case r'job_title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobTitle = valueDes;
          break;
        case r'job_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jobUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchResultResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchResultResponseBuilder();
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

