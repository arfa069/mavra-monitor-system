//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/threshold_percent.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'alert_create.g.dart';

/// Schema for creating an alert.
///
/// Properties:
/// * [productId] - Product ID to alert on
/// * [active] - Whether alert is active
/// * [thresholdPercent] 
@BuiltValue()
abstract class AlertCreate implements Built<AlertCreate, AlertCreateBuilder> {
  /// Product ID to alert on
  @BuiltValueField(wireName: r'product_id')
  int get productId;

  /// Whether alert is active
  @BuiltValueField(wireName: r'active')
  bool? get active;

  @BuiltValueField(wireName: r'threshold_percent')
  ThresholdPercent? get thresholdPercent;

  AlertCreate._();

  factory AlertCreate([void updates(AlertCreateBuilder b)]) = _$AlertCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AlertCreateBuilder b) => b
      ..active = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<AlertCreate> get serializer => _$AlertCreateSerializer();
}

class _$AlertCreateSerializer implements PrimitiveSerializer<AlertCreate> {
  @override
  final Iterable<Type> types = const [AlertCreate, _$AlertCreate];

  @override
  final String wireName = r'AlertCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AlertCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'product_id';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(int),
    );
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType(bool),
      );
    }
    if (object.thresholdPercent != null) {
      yield r'threshold_percent';
      yield serializers.serialize(
        object.thresholdPercent,
        specifiedType: const FullType.nullable(ThresholdPercent),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AlertCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AlertCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'product_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.productId = valueDes;
          break;
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        case r'threshold_percent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ThresholdPercent),
          ) as ThresholdPercent?;
          if (valueDes == null) continue;
          result.thresholdPercent.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AlertCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AlertCreateBuilder();
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

