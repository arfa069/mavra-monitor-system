//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/schedule_info.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'scheduler_jobs_response.g.dart';

/// SchedulerJobsResponse
///
/// Properties:
/// * [jobConfigs] 
/// * [productPlatforms] 
@BuiltValue()
abstract class SchedulerJobsResponse implements Built<SchedulerJobsResponse, SchedulerJobsResponseBuilder> {
  @BuiltValueField(wireName: r'job_configs')
  BuiltMap<String, ScheduleInfo>? get jobConfigs;

  @BuiltValueField(wireName: r'product_platforms')
  BuiltMap<String, ScheduleInfo>? get productPlatforms;

  SchedulerJobsResponse._();

  factory SchedulerJobsResponse([void updates(SchedulerJobsResponseBuilder b)]) = _$SchedulerJobsResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SchedulerJobsResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SchedulerJobsResponse> get serializer => _$SchedulerJobsResponseSerializer();
}

class _$SchedulerJobsResponseSerializer implements PrimitiveSerializer<SchedulerJobsResponse> {
  @override
  final Iterable<Type> types = const [SchedulerJobsResponse, _$SchedulerJobsResponse];

  @override
  final String wireName = r'SchedulerJobsResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SchedulerJobsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.jobConfigs != null) {
      yield r'job_configs';
      yield serializers.serialize(
        object.jobConfigs,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType(ScheduleInfo)]),
      );
    }
    if (object.productPlatforms != null) {
      yield r'product_platforms';
      yield serializers.serialize(
        object.productPlatforms,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType(ScheduleInfo)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SchedulerJobsResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SchedulerJobsResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'job_configs':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(ScheduleInfo)]),
          ) as BuiltMap<String, ScheduleInfo>;
          result.jobConfigs.replace(valueDes);
          break;
        case r'product_platforms':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType(ScheduleInfo)]),
          ) as BuiltMap<String, ScheduleInfo>;
          result.productPlatforms.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SchedulerJobsResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SchedulerJobsResponseBuilder();
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

