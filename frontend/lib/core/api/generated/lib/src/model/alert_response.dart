//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'alert_response.g.dart';

/// Schema for alert response.
///
/// Properties:
/// * [active] 
/// * [alertType] 
/// * [createdAt] 
/// * [id] 
/// * [lastNotifiedAt] 
/// * [lastNotifiedPrice] 
/// * [productId] 
/// * [thresholdPercent] 
/// * [updatedAt] 
@BuiltValue()
abstract class AlertResponse implements Built<AlertResponse, AlertResponseBuilder> {
  @BuiltValueField(wireName: r'active')
  bool get active;

  @BuiltValueField(wireName: r'alert_type')
  String get alertType;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'last_notified_at')
  DateTime? get lastNotifiedAt;

  @BuiltValueField(wireName: r'last_notified_price')
  String? get lastNotifiedPrice;

  @BuiltValueField(wireName: r'product_id')
  int get productId;

  @BuiltValueField(wireName: r'threshold_percent')
  String? get thresholdPercent;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  AlertResponse._();

  factory AlertResponse([void updates(AlertResponseBuilder b)]) = _$AlertResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AlertResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AlertResponse> get serializer => _$AlertResponseSerializer();
}

class _$AlertResponseSerializer implements PrimitiveSerializer<AlertResponse> {
  @override
  final Iterable<Type> types = const [AlertResponse, _$AlertResponse];

  @override
  final String wireName = r'AlertResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AlertResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'active';
    yield serializers.serialize(
      object.active,
      specifiedType: const FullType(bool),
    );
    yield r'alert_type';
    yield serializers.serialize(
      object.alertType,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'last_notified_at';
    yield object.lastNotifiedAt == null ? null : serializers.serialize(
      object.lastNotifiedAt,
      specifiedType: const FullType.nullable(DateTime),
    );
    yield r'last_notified_price';
    yield object.lastNotifiedPrice == null ? null : serializers.serialize(
      object.lastNotifiedPrice,
      specifiedType: const FullType.nullable(String),
    );
    yield r'product_id';
    yield serializers.serialize(
      object.productId,
      specifiedType: const FullType(int),
    );
    yield r'threshold_percent';
    yield object.thresholdPercent == null ? null : serializers.serialize(
      object.thresholdPercent,
      specifiedType: const FullType.nullable(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AlertResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AlertResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.active = valueDes;
          break;
        case r'alert_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.alertType = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'last_notified_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastNotifiedAt = valueDes;
          break;
        case r'last_notified_price':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.lastNotifiedPrice = valueDes;
          break;
        case r'product_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.productId = valueDes;
          break;
        case r'threshold_percent':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.thresholdPercent = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AlertResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AlertResponseBuilder();
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

