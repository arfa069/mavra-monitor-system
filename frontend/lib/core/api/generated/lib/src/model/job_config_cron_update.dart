//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'job_config_cron_update.g.dart';

/// Schema for updating only the cron settings of a job search config.
///
/// Properties:
/// * [cronExpression] 
/// * [cronTimezone] 
@BuiltValue()
abstract class JobConfigCronUpdate implements Built<JobConfigCronUpdate, JobConfigCronUpdateBuilder> {
  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  @BuiltValueField(wireName: r'cron_timezone')
  String? get cronTimezone;

  JobConfigCronUpdate._();

  factory JobConfigCronUpdate([void updates(JobConfigCronUpdateBuilder b)]) = _$JobConfigCronUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(JobConfigCronUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<JobConfigCronUpdate> get serializer => _$JobConfigCronUpdateSerializer();
}

class _$JobConfigCronUpdateSerializer implements PrimitiveSerializer<JobConfigCronUpdate> {
  @override
  final Iterable<Type> types = const [JobConfigCronUpdate, _$JobConfigCronUpdate];

  @override
  final String wireName = r'JobConfigCronUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    JobConfigCronUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
  }

  @override
  Object serialize(
    Serializers serializers,
    JobConfigCronUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required JobConfigCronUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  JobConfigCronUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = JobConfigCronUpdateBuilder();
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

