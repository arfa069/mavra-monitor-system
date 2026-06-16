//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/threshold_percent1.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'alert_update.g.dart';

/// Schema for updating an alert.
///
/// Properties:
/// * [active] 
/// * [thresholdPercent] 
@BuiltValue()
abstract class AlertUpdate implements Built<AlertUpdate, AlertUpdateBuilder> {
  @BuiltValueField(wireName: r'active')
  bool? get active;

  @BuiltValueField(wireName: r'threshold_percent')
  ThresholdPercent1? get thresholdPercent;

  AlertUpdate._();

  factory AlertUpdate([void updates(AlertUpdateBuilder b)]) = _$AlertUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AlertUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AlertUpdate> get serializer => _$AlertUpdateSerializer();
}

class _$AlertUpdateSerializer implements PrimitiveSerializer<AlertUpdate> {
  @override
  final Iterable<Type> types = const [AlertUpdate, _$AlertUpdate];

  @override
  final String wireName = r'AlertUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AlertUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.active != null) {
      yield r'active';
      yield serializers.serialize(
        object.active,
        specifiedType: const FullType.nullable(bool),
      );
    }
    if (object.thresholdPercent != null) {
      yield r'threshold_percent';
      yield serializers.serialize(
        object.thresholdPercent,
        specifiedType: const FullType.nullable(ThresholdPercent1),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    AlertUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AlertUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(bool),
          ) as bool?;
          if (valueDes == null) continue;
          result.active = valueDes;
          break;
        case r'threshold_percent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(ThresholdPercent1),
          ) as ThresholdPercent1?;
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
  AlertUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AlertUpdateBuilder();
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

