//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_summary_response.g.dart';

/// SmartHomeSummaryResponse
///
/// Properties:
/// * [activeCount] 
/// * [configured] 
/// * [connected] 
/// * [unavailableCount] 
@BuiltValue()
abstract class SmartHomeSummaryResponse implements Built<SmartHomeSummaryResponse, SmartHomeSummaryResponseBuilder> {
  @BuiltValueField(wireName: r'active_count')
  int get activeCount;

  @BuiltValueField(wireName: r'configured')
  bool get configured;

  @BuiltValueField(wireName: r'connected')
  bool get connected;

  @BuiltValueField(wireName: r'unavailable_count')
  int get unavailableCount;

  SmartHomeSummaryResponse._();

  factory SmartHomeSummaryResponse([void updates(SmartHomeSummaryResponseBuilder b)]) = _$SmartHomeSummaryResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeSummaryResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeSummaryResponse> get serializer => _$SmartHomeSummaryResponseSerializer();
}

class _$SmartHomeSummaryResponseSerializer implements PrimitiveSerializer<SmartHomeSummaryResponse> {
  @override
  final Iterable<Type> types = const [SmartHomeSummaryResponse, _$SmartHomeSummaryResponse];

  @override
  final String wireName = r'SmartHomeSummaryResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeSummaryResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'active_count';
    yield serializers.serialize(
      object.activeCount,
      specifiedType: const FullType(int),
    );
    yield r'configured';
    yield serializers.serialize(
      object.configured,
      specifiedType: const FullType(bool),
    );
    yield r'connected';
    yield serializers.serialize(
      object.connected,
      specifiedType: const FullType(bool),
    );
    yield r'unavailable_count';
    yield serializers.serialize(
      object.unavailableCount,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeSummaryResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeSummaryResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.activeCount = valueDes;
          break;
        case r'configured':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.configured = valueDes;
          break;
        case r'connected':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.connected = valueDes;
          break;
        case r'unavailable_count':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.unavailableCount = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeSummaryResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeSummaryResponseBuilder();
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

