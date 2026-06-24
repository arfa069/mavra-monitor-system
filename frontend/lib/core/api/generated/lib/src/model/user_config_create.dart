//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_config_create.g.dart';

/// Schema for creating user configuration.
///
/// Properties:
/// * [dataRetentionDays] - Data retention period in days
/// * [feishuWebhookUrl] - Feishu webhook URL for notifications
@BuiltValue()
abstract class UserConfigCreate implements Built<UserConfigCreate, UserConfigCreateBuilder> {
  /// Data retention period in days
  @BuiltValueField(wireName: r'data_retention_days')
  int? get dataRetentionDays;

  /// Feishu webhook URL for notifications
  @BuiltValueField(wireName: r'feishu_webhook_url')
  String? get feishuWebhookUrl;

  UserConfigCreate._();

  factory UserConfigCreate([void updates(UserConfigCreateBuilder b)]) = _$UserConfigCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserConfigCreateBuilder b) => b
      ..dataRetentionDays = 365
      ..feishuWebhookUrl = '';

  @BuiltValueSerializer(custom: true)
  static Serializer<UserConfigCreate> get serializer => _$UserConfigCreateSerializer();
}

class _$UserConfigCreateSerializer implements PrimitiveSerializer<UserConfigCreate> {
  @override
  final Iterable<Type> types = const [UserConfigCreate, _$UserConfigCreate];

  @override
  final String wireName = r'UserConfigCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserConfigCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.dataRetentionDays != null) {
      yield r'data_retention_days';
      yield serializers.serialize(
        object.dataRetentionDays,
        specifiedType: const FullType(int),
      );
    }
    if (object.feishuWebhookUrl != null) {
      yield r'feishu_webhook_url';
      yield serializers.serialize(
        object.feishuWebhookUrl,
        specifiedType: const FullType(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserConfigCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserConfigCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data_retention_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.dataRetentionDays = valueDes;
          break;
        case r'feishu_webhook_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.feishuWebhookUrl = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserConfigCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserConfigCreateBuilder();
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

