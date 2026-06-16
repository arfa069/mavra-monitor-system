//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/job_config_schedule_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_config_schedules_response.g.dart';

/// JobConfigSchedulesResponse
///
/// Properties:
/// * [configs] 
@BuiltValue()
abstract class JobConfigSchedulesResponse implements Built<JobConfigSchedulesResponse, JobConfigSchedulesResponseBuilder> {
  @BuiltValueField(wireName: r'configs')
  BuiltList<JobConfigScheduleInfo>? get configs;

  JobConfigSchedulesResponse._();

  factory JobConfigSchedulesResponse([void updates(JobConfigSchedulesResponseBuilder b)]) = _$JobConfigSchedulesResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobConfigSchedulesResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobConfigSchedulesResponse> get serializer => _$JobConfigSchedulesResponseSerializer();
}

class _$JobConfigSchedulesResponseSerializer implements PrimitiveSerializer<JobConfigSchedulesResponse> {
  @override
  final Iterable<Type> types = const [JobConfigSchedulesResponse, _$JobConfigSchedulesResponse];

  @override
  final String wireName = r'JobConfigSchedulesResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobConfigSchedulesResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.configs != null) {
      yield r'configs';
      yield serializers.serialize(
        object.configs,
        specifiedType: const FullType(BuiltList, [FullType(JobConfigScheduleInfo)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobConfigSchedulesResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobConfigSchedulesResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'configs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(JobConfigScheduleInfo)]),
          ) as BuiltList<JobConfigScheduleInfo>;
          result.configs.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobConfigSchedulesResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobConfigSchedulesResponseBuilder();
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

