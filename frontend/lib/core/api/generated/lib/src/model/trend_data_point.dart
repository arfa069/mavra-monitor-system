//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trend_data_point.g.dart';

/// Single data point for trend charts.
///
/// Properties:
/// * [label] 
/// * [value] 
@BuiltValue()
abstract class TrendDataPoint implements Built<TrendDataPoint, TrendDataPointBuilder> {
  @BuiltValueField(wireName: r'label')
  String get label;

  @BuiltValueField(wireName: r'value')
  num get value;

  TrendDataPoint._();

  factory TrendDataPoint([void updates(TrendDataPointBuilder b)]) = _$TrendDataPoint;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrendDataPointBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrendDataPoint> get serializer => _$TrendDataPointSerializer();
}

class _$TrendDataPointSerializer implements PrimitiveSerializer<TrendDataPoint> {
  @override
  final Iterable<Type> types = const [TrendDataPoint, _$TrendDataPoint];

  @override
  final String wireName = r'TrendDataPoint';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrendDataPoint object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'label';
    yield serializers.serialize(
      object.label,
      specifiedType: const FullType(String),
    );
    yield r'value';
    yield serializers.serialize(
      object.value,
      specifiedType: const FullType(num),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TrendDataPoint object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrendDataPointBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'label':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.label = valueDes;
          break;
        case r'value':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(num),
          ) as num;
          result.value = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TrendDataPoint deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrendDataPointBuilder();
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

