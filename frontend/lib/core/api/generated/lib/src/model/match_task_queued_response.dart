//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'match_task_queued_response.g.dart';

/// MatchTaskQueuedResponse
///
/// Properties:
/// * [status] 
/// * [taskId] 
/// * [total] 
/// * [reason] 
@BuiltValue()
abstract class MatchTaskQueuedResponse implements Built<MatchTaskQueuedResponse, MatchTaskQueuedResponseBuilder> {
  @BuiltValueField(wireName: r'status')
  MatchTaskQueuedResponseStatusEnum get status;
  // enum statusEnum {  pending,  completed,  };

  @BuiltValueField(wireName: r'task_id')
  String? get taskId;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'reason')
  String? get reason;

  MatchTaskQueuedResponse._();

  factory MatchTaskQueuedResponse([void updates(MatchTaskQueuedResponseBuilder b)]) = _$MatchTaskQueuedResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MatchTaskQueuedResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MatchTaskQueuedResponse> get serializer => _$MatchTaskQueuedResponseSerializer();
}

class _$MatchTaskQueuedResponseSerializer implements PrimitiveSerializer<MatchTaskQueuedResponse> {
  @override
  final Iterable<Type> types = const [MatchTaskQueuedResponse, _$MatchTaskQueuedResponse];

  @override
  final String wireName = r'MatchTaskQueuedResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MatchTaskQueuedResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(MatchTaskQueuedResponseStatusEnum),
    );
    yield r'task_id';
    yield object.taskId == null ? null : serializers.serialize(
      object.taskId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    if (object.reason != null) {
      yield r'reason';
      yield serializers.serialize(
        object.reason,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    MatchTaskQueuedResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MatchTaskQueuedResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(MatchTaskQueuedResponseStatusEnum),
          ) as MatchTaskQueuedResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'task_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.taskId = valueDes;
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'reason':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reason = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MatchTaskQueuedResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MatchTaskQueuedResponseBuilder();
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

class MatchTaskQueuedResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'pending')
  static const MatchTaskQueuedResponseStatusEnum pending = _$matchTaskQueuedResponseStatusEnum_pending;
  @BuiltValueEnumConst(wireName: r'completed')
  static const MatchTaskQueuedResponseStatusEnum completed = _$matchTaskQueuedResponseStatusEnum_completed;

  static Serializer<MatchTaskQueuedResponseStatusEnum> get serializer => _$matchTaskQueuedResponseStatusEnumSerializer;

  const MatchTaskQueuedResponseStatusEnum._(String name): super(name);

  static BuiltSet<MatchTaskQueuedResponseStatusEnum> get values => _$matchTaskQueuedResponseStatusEnumValues;
  static MatchTaskQueuedResponseStatusEnum valueOf(String name) => _$matchTaskQueuedResponseStatusEnumValueOf(name);
}

