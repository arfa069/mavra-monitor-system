//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/scheduler_jobs_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'scheduler_status_response.g.dart';

/// SchedulerStatusResponse
///
/// Properties:
/// * [scheduler] 
/// * [jobs] 
/// * [timezone] 
@BuiltValue()
abstract class SchedulerStatusResponse implements Built<SchedulerStatusResponse, SchedulerStatusResponseBuilder> {
  @BuiltValueField(wireName: r'scheduler')
  String get scheduler;

  @BuiltValueField(wireName: r'jobs')
  SchedulerJobsResponse? get jobs;

  @BuiltValueField(wireName: r'timezone')
  String? get timezone;

  SchedulerStatusResponse._();

  factory SchedulerStatusResponse([void updates(SchedulerStatusResponseBuilder b)]) = _$SchedulerStatusResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SchedulerStatusResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SchedulerStatusResponse> get serializer => _$SchedulerStatusResponseSerializer();
}

class _$SchedulerStatusResponseSerializer implements PrimitiveSerializer<SchedulerStatusResponse> {
  @override
  final Iterable<Type> types = const [SchedulerStatusResponse, _$SchedulerStatusResponse];

  @override
  final String wireName = r'SchedulerStatusResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SchedulerStatusResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'scheduler';
    yield serializers.serialize(
      object.scheduler,
      specifiedType: const FullType(String),
    );
    if (object.jobs != null) {
      yield r'jobs';
      yield serializers.serialize(
        object.jobs,
        specifiedType: const FullType.nullable(SchedulerJobsResponse),
      );
    }
    if (object.timezone != null) {
      yield r'timezone';
      yield serializers.serialize(
        object.timezone,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SchedulerStatusResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SchedulerStatusResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'scheduler':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.scheduler = valueDes;
          break;
        case r'jobs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(SchedulerJobsResponse),
          ) as SchedulerJobsResponse?;
          if (valueDes == null) continue;
          result.jobs.replace(valueDes);
          break;
        case r'timezone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.timezone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SchedulerStatusResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SchedulerStatusResponseBuilder();
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

