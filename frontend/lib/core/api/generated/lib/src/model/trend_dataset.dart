//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/trend_data_point.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trend_dataset.g.dart';

/// Dataset for a trend chart.
///
/// Properties:
/// * [data] 
/// * [label] 
@BuiltValue()
abstract class TrendDataset implements Built<TrendDataset, TrendDatasetBuilder> {
  @BuiltValueField(wireName: r'data')
  BuiltList<TrendDataPoint> get data;

  @BuiltValueField(wireName: r'label')
  String get label;

  TrendDataset._();

  factory TrendDataset([void updates(TrendDatasetBuilder b)]) = _$TrendDataset;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrendDatasetBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrendDataset> get serializer => _$TrendDatasetSerializer();
}

class _$TrendDatasetSerializer implements PrimitiveSerializer<TrendDataset> {
  @override
  final Iterable<Type> types = const [TrendDataset, _$TrendDataset];

  @override
  final String wireName = r'TrendDataset';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrendDataset object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'data';
    yield serializers.serialize(
      object.data,
      specifiedType: const FullType(BuiltList, [FullType(TrendDataPoint)]),
    );
    yield r'label';
    yield serializers.serialize(
      object.label,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TrendDataset object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrendDatasetBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TrendDataPoint)]),
          ) as BuiltList<TrendDataPoint>;
          result.data.replace(valueDes);
          break;
        case r'label':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.label = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TrendDataset deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrendDatasetBuilder();
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

