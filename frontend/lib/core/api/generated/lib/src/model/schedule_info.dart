//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'schedule_info.g.dart';

/// ScheduleInfo
///
/// Properties:
/// * [cronExpression] 
/// * [nextRunAt] 
@BuiltValue()
abstract class ScheduleInfo implements Built<ScheduleInfo, ScheduleInfoBuilder> {
  @BuiltValueField(wireName: r'cron_expression')
  String? get cronExpression;

  @BuiltValueField(wireName: r'next_run_at')
  String? get nextRunAt;

  ScheduleInfo._();

  factory ScheduleInfo([void updates(ScheduleInfoBuilder b)]) = _$ScheduleInfo;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ScheduleInfoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ScheduleInfo> get serializer => _$ScheduleInfoSerializer();
}

class _$ScheduleInfoSerializer implements PrimitiveSerializer<ScheduleInfo> {
  @override
  final Iterable<Type> types = const [ScheduleInfo, _$ScheduleInfo];

  @override
  final String wireName = r'ScheduleInfo';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ScheduleInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    ScheduleInfo object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ScheduleInfoBuilder result,
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
  ScheduleInfo deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ScheduleInfoBuilder();
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

