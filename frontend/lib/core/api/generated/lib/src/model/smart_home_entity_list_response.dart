//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/smart_home_entity.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_entity_list_response.g.dart';

/// SmartHomeEntityListResponse
///
/// Properties:
/// * [connected] 
/// * [items] 
/// * [total] 
/// * [lastError] 
@BuiltValue()
abstract class SmartHomeEntityListResponse implements Built<SmartHomeEntityListResponse, SmartHomeEntityListResponseBuilder> {
  @BuiltValueField(wireName: r'connected')
  bool get connected;

  @BuiltValueField(wireName: r'items')
  BuiltList<SmartHomeEntity> get items;

  @BuiltValueField(wireName: r'total')
  int get total;

  @BuiltValueField(wireName: r'last_error')
  String? get lastError;

  SmartHomeEntityListResponse._();

  factory SmartHomeEntityListResponse([void updates(SmartHomeEntityListResponseBuilder b)]) = _$SmartHomeEntityListResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeEntityListResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeEntityListResponse> get serializer => _$SmartHomeEntityListResponseSerializer();
}

class _$SmartHomeEntityListResponseSerializer implements PrimitiveSerializer<SmartHomeEntityListResponse> {
  @override
  final Iterable<Type> types = const [SmartHomeEntityListResponse, _$SmartHomeEntityListResponse];

  @override
  final String wireName = r'SmartHomeEntityListResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeEntityListResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'connected';
    yield serializers.serialize(
      object.connected,
      specifiedType: const FullType(bool),
    );
    yield r'items';
    yield serializers.serialize(
      object.items,
      specifiedType: const FullType(BuiltList, [FullType(SmartHomeEntity)]),
    );
    yield r'total';
    yield serializers.serialize(
      object.total,
      specifiedType: const FullType(int),
    );
    if (object.lastError != null) {
      yield r'last_error';
      yield serializers.serialize(
        object.lastError,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeEntityListResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeEntityListResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'connected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.connected = valueDes;
          break;
        case r'items':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(SmartHomeEntity)]),
          ) as BuiltList<SmartHomeEntity>;
          result.items.replace(valueDes);
          break;
        case r'total':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.total = valueDes;
          break;
        case r'last_error':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastError = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeEntityListResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeEntityListResponseBuilder();
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

