//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'task_error_response.g.dart';

/// TaskErrorResponse
///
/// Properties:
/// * [reason] 
/// * [status] 
@BuiltValue()
abstract class TaskErrorResponse implements Built<TaskErrorResponse, TaskErrorResponseBuilder> {
  @BuiltValueField(wireName: r'reason')
  String get reason;

  @BuiltValueField(wireName: r'status')
  TaskErrorResponseStatusEnum get status;
  // enum statusEnum {  error,  };

  TaskErrorResponse._();

  factory TaskErrorResponse([void updates(TaskErrorResponseBuilder b)]) = _$TaskErrorResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TaskErrorResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TaskErrorResponse> get serializer => _$TaskErrorResponseSerializer();
}

class _$TaskErrorResponseSerializer implements PrimitiveSerializer<TaskErrorResponse> {
  @override
  final Iterable<Type> types = const [TaskErrorResponse, _$TaskErrorResponse];

  @override
  final String wireName = r'TaskErrorResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TaskErrorResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'reason';
    yield serializers.serialize(
      object.reason,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(TaskErrorResponseStatusEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TaskErrorResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TaskErrorResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reason = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(TaskErrorResponseStatusEnum),
          ) as TaskErrorResponseStatusEnum;
          result.status = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TaskErrorResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TaskErrorResponseBuilder();
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

class TaskErrorResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'error')
  static const TaskErrorResponseStatusEnum error = _$taskErrorResponseStatusEnum_error;

  static Serializer<TaskErrorResponseStatusEnum> get serializer => _$taskErrorResponseStatusEnumSerializer;

  const TaskErrorResponseStatusEnum._(String name): super(name);

  static BuiltSet<TaskErrorResponseStatusEnum> get values => _$taskErrorResponseStatusEnumValues;
  static TaskErrorResponseStatusEnum valueOf(String name) => _$taskErrorResponseStatusEnumValueOf(name);
}

