//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'task_progress_response.g.dart';

/// TaskProgressResponse
///
/// Properties:
/// * [status] 
/// * [taskId] 
/// * [details] 
/// * [errors] 
/// * [finishedAt] 
/// * [heartbeatAt] 
/// * [leaseUntil] 
/// * [reason] 
/// * [startedAt] 
/// * [success] 
/// * [total] 
/// * [workerId] 
@BuiltValue()
abstract class TaskProgressResponse implements Built<TaskProgressResponse, TaskProgressResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  TaskProgressResponseStatusEnum get status;
  // enum statusEnum {  pending,  running,  completed,  failed,  error,  };

  @BuiltValueField(wireName: r'task_id')
  String get taskId;

  @BuiltValueField(wireName: r'details')
  BuiltList<JsonObject?>? get details;

  @BuiltValueField(wireName: r'errors')
  int? get errors;

  @BuiltValueField(wireName: r'finished_at')
  DateTime? get finishedAt;

  @BuiltValueField(wireName: r'heartbeat_at')
  DateTime? get heartbeatAt;

  @BuiltValueField(wireName: r'lease_until')
  DateTime? get leaseUntil;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  @BuiltValueField(wireName: r'started_at')
  DateTime? get startedAt;

  @BuiltValueField(wireName: r'success')
  int? get success;

  @BuiltValueField(wireName: r'total')
  int? get total;

  @BuiltValueField(wireName: r'worker_id')
  String? get workerId;

  TaskProgressResponse._();

  factory TaskProgressResponse([void updates(TaskProgressResponseBuilder b)]) = _$TaskProgressResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TaskProgressResponseBuilder b) => b
      ..errors = 0
      ..success = 0
      ..total = 0;

  @BuiltValueSerializer(custom: true)
  static Serializer<TaskProgressResponse> get serializer => _$TaskProgressResponseSerializer();
}

class _$TaskProgressResponseSerializer implements PrimitiveSerializer<TaskProgressResponse> {
  @override
  final Iterable<Type> types = const [TaskProgressResponse, _$TaskProgressResponse];

  @override
  final String wireName = r'TaskProgressResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TaskProgressResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TaskProgressResponseStatusEnum),
    );
    yield r'task_id';
    yield serializers.serialize(
      object.taskId,
      specifiedType: const FullType(String),
    );
    if (object.details != null) {
      yield r'details';
      yield serializers.serialize(
        object.details,
        specifiedType: const FullType.nullable(BuiltList, [FullType.nullable(JsonObject)]),
      );
    }
    if (object.errors != null) {
      yield r'errors';
      yield serializers.serialize(
        object.errors,
        specifiedType: const FullType(int),
      );
    }
    if (object.finishedAt != null) {
      yield r'finished_at';
      yield serializers.serialize(
        object.finishedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.heartbeatAt != null) {
      yield r'heartbeat_at';
      yield serializers.serialize(
        object.heartbeatAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.leaseUntil != null) {
      yield r'lease_until';
      yield serializers.serialize(
        object.leaseUntil,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.startedAt != null) {
      yield r'started_at';
      yield serializers.serialize(
        object.startedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.success != null) {
      yield r'success';
      yield serializers.serialize(
        object.success,
        specifiedType: const FullType(int),
      );
    }
    if (object.total != null) {
      yield r'total';
      yield serializers.serialize(
        object.total,
        specifiedType: const FullType(int),
      );
    }
    if (object.workerId != null) {
      yield r'worker_id';
      yield serializers.serialize(
        object.workerId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TaskProgressResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TaskProgressResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TaskProgressResponseStatusEnum),
          ) as TaskProgressResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'task_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.taskId = valueDes;
          break;
        case r'details':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType.nullable(JsonObject)]),
          ) as BuiltList<JsonObject?>?;
          if (valueDes == null) continue;
          result.details.replace(valueDes);
          break;
        case r'errors':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.errors = valueDes;
          break;
        case r'finished_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.finishedAt = valueDes;
          break;
        case r'heartbeat_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.heartbeatAt = valueDes;
          break;
        case r'lease_until':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.leaseUntil = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        case r'started_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.startedAt = valueDes;
          break;
        case r'success':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.success = valueDes;
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'worker_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.workerId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TaskProgressResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TaskProgressResponseBuilder();
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

class TaskProgressResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'pending')
  static const TaskProgressResponseStatusEnum pending = _$taskProgressResponseStatusEnum_pending;
  @BuiltValueEnumConst(wireName: r'running')
  static const TaskProgressResponseStatusEnum running = _$taskProgressResponseStatusEnum_running;
  @BuiltValueEnumConst(wireName: r'completed')
  static const TaskProgressResponseStatusEnum completed = _$taskProgressResponseStatusEnum_completed;
  @BuiltValueEnumConst(wireName: r'failed')
  static const TaskProgressResponseStatusEnum failed = _$taskProgressResponseStatusEnum_failed;
  @BuiltValueEnumConst(wireName: r'error')
  static const TaskProgressResponseStatusEnum error = _$taskProgressResponseStatusEnum_error;

  static Serializer<TaskProgressResponseStatusEnum> get serializer => _$taskProgressResponseStatusEnumSerializer;

  const TaskProgressResponseStatusEnum._(String name): super(name);

  static BuiltSet<TaskProgressResponseStatusEnum> get values => _$taskProgressResponseStatusEnumValues;
  static TaskProgressResponseStatusEnum valueOf(String name) => _$taskProgressResponseStatusEnumValueOf(name);
}

