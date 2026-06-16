//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/trend_dataset.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'trend_response.g.dart';

/// Trend chart data response.
///
/// Properties:
/// * [datasets] 
/// * [labels] 
@BuiltValue()
abstract class TrendResponse implements Built<TrendResponse, TrendResponseBuilder> {
  @BuiltValueField(wireName: r'datasets')
  BuiltList<TrendDataset> get datasets;

  @BuiltValueField(wireName: r'labels')
  BuiltList<String> get labels;

  TrendResponse._();

  factory TrendResponse([void updates(TrendResponseBuilder b)]) = _$TrendResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TrendResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<TrendResponse> get serializer => _$TrendResponseSerializer();
}

class _$TrendResponseSerializer implements PrimitiveSerializer<TrendResponse> {
  @override
  final Iterable<Type> types = const [TrendResponse, _$TrendResponse];

  @override
  final String wireName = r'TrendResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TrendResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'datasets';
    yield serializers.serialize(
      object.datasets,
      specifiedType: const FullType(BuiltList, [FullType(TrendDataset)]),
    );
    yield r'labels';
    yield serializers.serialize(
      object.labels,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    TrendResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TrendResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'datasets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(TrendDataset)]),
          ) as BuiltList<TrendDataset>;
          result.datasets.replace(valueDes);
          break;
        case r'labels':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.labels.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TrendResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TrendResponseBuilder();
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

