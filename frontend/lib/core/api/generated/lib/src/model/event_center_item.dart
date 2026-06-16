//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'event_center_item.g.dart';

/// Unified event-center row.
///
/// Properties:
/// * [category] 
/// * [entityId] 
/// * [entityType] 
/// * [eventType] 
/// * [id] 
/// * [kind] 
/// * [message] 
/// * [occurredAt] 
/// * [payload] 
/// * [severity] 
/// * [source_] 
/// * [status] 
/// * [traceId] 
/// * [userId] 
@BuiltValue()
abstract class EventCenterItem implements Built<EventCenterItem, EventCenterItemBuilder> {
  @BuiltValueField(wireName: r'category')
  String get category;

  @BuiltValueField(wireName: r'entity_id')
  String? get entityId;

  @BuiltValueField(wireName: r'entity_type')
  String? get entityType;

  @BuiltValueField(wireName: r'event_type')
  String get eventType;

  @BuiltValueField(wireName: r'id')
  String get id;

  @BuiltValueField(wireName: r'kind')
  EventCenterItemKindEnum get kind;
  // enum kindEnum {  audit,  system,  platform,  };

  @BuiltValueField(wireName: r'message')
  String get message;

  @BuiltValueField(wireName: r'occurred_at')
  DateTime get occurredAt;

  @BuiltValueField(wireName: r'payload')
  BuiltMap<String, JsonObject?>? get payload;

  @BuiltValueField(wireName: r'severity')
  String get severity;

  @BuiltValueField(wireName: r'source')
  String get source_;

  @BuiltValueField(wireName: r'status')
  String? get status;

  @BuiltValueField(wireName: r'trace_id')
  String? get traceId;

  @BuiltValueField(wireName: r'user_id')
  int? get userId;

  EventCenterItem._();

  factory EventCenterItem([void updates(EventCenterItemBuilder b)]) = _$EventCenterItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EventCenterItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EventCenterItem> get serializer => _$EventCenterItemSerializer();
}

class _$EventCenterItemSerializer implements PrimitiveSerializer<EventCenterItem> {
  @override
  final Iterable<Type> types = const [EventCenterItem, _$EventCenterItem];

  @override
  final String wireName = r'EventCenterItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EventCenterItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'category';
    yield serializers.serialize(
      object.category,
      specifiedType: const FullType(String),
    );
    yield r'entity_id';
    yield object.entityId == null ? null : serializers.serialize(
      object.entityId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'entity_type';
    yield object.entityType == null ? null : serializers.serialize(
      object.entityType,
      specifiedType: const FullType.nullable(String),
    );
    yield r'event_type';
    yield serializers.serialize(
      object.eventType,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'kind';
    yield serializers.serialize(
      object.kind,
      specifiedType: const FullType(EventCenterItemKindEnum),
    );
    yield r'message';
    yield serializers.serialize(
      object.message,
      specifiedType: const FullType(String),
    );
    yield r'occurred_at';
    yield serializers.serialize(
      object.occurredAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'payload';
    yield object.payload == null ? null : serializers.serialize(
      object.payload,
      specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
    yield r'severity';
    yield serializers.serialize(
      object.severity,
      specifiedType: const FullType(String),
    );
    yield r'source';
    yield serializers.serialize(
      object.source_,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield object.status == null ? null : serializers.serialize(
      object.status,
      specifiedType: const FullType.nullable(String),
    );
    yield r'trace_id';
    yield object.traceId == null ? null : serializers.serialize(
      object.traceId,
      specifiedType: const FullType.nullable(String),
    );
    yield r'user_id';
    yield object.userId == null ? null : serializers.serialize(
      object.userId,
      specifiedType: const FullType.nullable(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EventCenterItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EventCenterItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.category = valueDes;
          break;
        case r'entity_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.entityId = valueDes;
          break;
        case r'entity_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.entityType = valueDes;
          break;
        case r'event_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.eventType = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EventCenterItemKindEnum),
          ) as EventCenterItemKindEnum;
          result.kind = valueDes;
          break;
        case r'message':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.message = valueDes;
          break;
        case r'occurred_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.occurredAt = valueDes;
          break;
        case r'payload':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>?;
          if (valueDes == null) continue;
          result.payload.replace(valueDes);
          break;
        case r'severity':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.severity = valueDes;
          break;
        case r'source':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.source_ = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'trace_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.traceId = valueDes;
          break;
        case r'user_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.userId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EventCenterItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EventCenterItemBuilder();
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

class EventCenterItemKindEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'audit')
  static const EventCenterItemKindEnum audit = _$eventCenterItemKindEnum_audit;
  @BuiltValueEnumConst(wireName: r'system')
  static const EventCenterItemKindEnum system = _$eventCenterItemKindEnum_system;
  @BuiltValueEnumConst(wireName: r'platform')
  static const EventCenterItemKindEnum platform = _$eventCenterItemKindEnum_platform;

  static Serializer<EventCenterItemKindEnum> get serializer => _$eventCenterItemKindEnumSerializer;

  const EventCenterItemKindEnum._(String name): super(name);

  static BuiltSet<EventCenterItemKindEnum> get values => _$eventCenterItemKindEnumValues;
  static EventCenterItemKindEnum valueOf(String name) => _$eventCenterItemKindEnumValueOf(name);
}

