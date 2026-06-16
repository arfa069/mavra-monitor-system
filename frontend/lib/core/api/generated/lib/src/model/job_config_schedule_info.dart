//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_config_schedule_info.g.dart';

/// JobConfigScheduleInfo
///
/// Properties:
/// * [configId] 
/// * [cronExpression] 
/// * [nextRunAt] 
@BuiltValue()
abstract class JobConfigScheduleInfo implements Built<JobConfigScheduleInfo, JobConfigScheduleInfoBuilder> {
  @BuiltValueField(wireName: r'config_id')
  int get configId;

  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  @BuiltValueField(wireName: r'next_run_at')
  String? get nextRunAt;

  JobConfigScheduleInfo._();

  factory JobConfigScheduleInfo([void updates(JobConfigScheduleInfoBuilder b)]) = _$JobConfigScheduleInfo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobConfigScheduleInfoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobConfigScheduleInfo> get serializer => _$JobConfigScheduleInfoSerializer();
}

class _$JobConfigScheduleInfoSerializer implements PrimitiveSerializer<JobConfigScheduleInfo> {
  @override
  final Iterable<Type> types = const [JobConfigScheduleInfo, _$JobConfigScheduleInfo];

  @override
  final String wireName = r'JobConfigScheduleInfo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobConfigScheduleInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'config_id';
    yield serializers.serialize(
      object.configId,
      specifiedType: const FullType(int),
    );
    if (object.cronExpression != null) {
      yield r'cron_expression';
      yield serializers.serialize(
        object.cronExpression,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.nextRunAt != null) {
      yield r'next_run_at';
      yield serializers.serialize(
        object.nextRunAt,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    JobConfigScheduleInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobConfigScheduleInfoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'config_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.configId = valueDes;
          break;
        case r'cron_expression':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.cronExpression = valueDes;
          break;
        case r'next_run_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nextRunAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobConfigScheduleInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobConfigScheduleInfoBuilder();
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

