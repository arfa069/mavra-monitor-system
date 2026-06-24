//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_analyze_request.g.dart';

/// MatchAnalyzeRequest
///
/// Properties:
/// * [resumeId] 
/// * [jobIds] 
@BuiltValue()
abstract class MatchAnalyzeRequest implements Built<MatchAnalyzeRequest, MatchAnalyzeRequestBuilder> {
  @BuiltValueField(wireName: r'resume_id')
  int get resumeId;

  @BuiltValueField(wireName: r'job_ids')
  BuiltList<int>? get jobIds;

  MatchAnalyzeRequest._();

  factory MatchAnalyzeRequest([void updates(MatchAnalyzeRequestBuilder b)]) = _$MatchAnalyzeRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchAnalyzeRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchAnalyzeRequest> get serializer => _$MatchAnalyzeRequestSerializer();
}

class _$MatchAnalyzeRequestSerializer implements PrimitiveSerializer<MatchAnalyzeRequest> {
  @override
  final Iterable<Type> types = const [MatchAnalyzeRequest, _$MatchAnalyzeRequest];

  @override
  final String wireName = r'MatchAnalyzeRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchAnalyzeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'resume_id';
    yield serializers.serialize(
      object.resumeId,
      specifiedType: const FullType(int),
    );
    if (object.jobIds != null) {
      yield r'job_ids';
      yield serializers.serialize(
        object.jobIds,
        specifiedType: const FullType.nullable(BuiltList, [FullType(int)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchAnalyzeRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchAnalyzeRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'resume_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.resumeId = valueDes;
          break;
        case r'job_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(int)]),
          ) as BuiltList<int>?;
          if (valueDes == null) continue;
          result.jobIds.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchAnalyzeRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchAnalyzeRequestBuilder();
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

