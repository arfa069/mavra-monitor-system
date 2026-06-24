//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'task_queued_response.g.dart';

/// TaskQueuedResponse
///
/// Properties:
/// * [status] 
/// * [message] 
/// * [reason] 
/// * [taskId] 
@BuiltValue()
abstract class TaskQueuedResponse implements Built<TaskQueuedResponse, TaskQueuedResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  TaskQueuedResponseStatusEnum get status;
  // enum statusEnum {  pending,  skipped,  error,  };

  @BuiltValueField(wireName: r'message')
  String? get message;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  @BuiltValueField(wireName: r'task_id')
  String? get taskId;

  TaskQueuedResponse._();

  factory TaskQueuedResponse([void updates(TaskQueuedResponseBuilder b)]) = _$TaskQueuedResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TaskQueuedResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TaskQueuedResponse> get serializer => _$TaskQueuedResponseSerializer();
}

class _$TaskQueuedResponseSerializer implements PrimitiveSerializer<TaskQueuedResponse> {
  @override
  final Iterable<Type> types = const [TaskQueuedResponse, _$TaskQueuedResponse];

  @override
  final String wireName = r'TaskQueuedResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TaskQueuedResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TaskQueuedResponseStatusEnum),
    );
    if (object.message != null) {
      yield r'message';
      yield serializers.serialize(
        object.message,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.taskId != null) {
      yield r'task_id';
      yield serializers.serialize(
        object.taskId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TaskQueuedResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TaskQueuedResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TaskQueuedResponseStatusEnum),
          ) as TaskQueuedResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.message = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'task_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.taskId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TaskQueuedResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TaskQueuedResponseBuilder();
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

class TaskQueuedResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'pending')
  static const TaskQueuedResponseStatusEnum pending = _$taskQueuedResponseStatusEnum_pending;
  @BuiltValueEnumConst(wireName: r'skipped')
  static const TaskQueuedResponseStatusEnum skipped = _$taskQueuedResponseStatusEnum_skipped;
  @BuiltValueEnumConst(wireName: r'error')
  static const TaskQueuedResponseStatusEnum error = _$taskQueuedResponseStatusEnum_error;

  static Serializer<TaskQueuedResponseStatusEnum> get serializer => _$taskQueuedResponseStatusEnumSerializer;

  const TaskQueuedResponseStatusEnum._(String name): super(name);

  static BuiltSet<TaskQueuedResponseStatusEnum> get values => _$taskQueuedResponseStatusEnumValues;
  static TaskQueuedResponseStatusEnum valueOf(String name) => _$taskQueuedResponseStatusEnumValueOf(name);
}

