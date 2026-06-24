//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_config_update.g.dart';

/// Schema for updating user configuration.
///
/// Properties:
/// * [dataRetentionDays] 
/// * [feishuWebhookUrl] - Feishu webhook URL
@BuiltValue()
abstract class UserConfigUpdate implements Built<UserConfigUpdate, UserConfigUpdateBuilder> {
  @BuiltValueField(wireName: r'data_retention_days')
  int? get dataRetentionDays;

  /// Feishu webhook URL
  @BuiltValueField(wireName: r'feishu_webhook_url')
  String? get feishuWebhookUrl;

  UserConfigUpdate._();

  factory UserConfigUpdate([void updates(UserConfigUpdateBuilder b)]) = _$UserConfigUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserConfigUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserConfigUpdate> get serializer => _$UserConfigUpdateSerializer();
}

class _$UserConfigUpdateSerializer implements PrimitiveSerializer<UserConfigUpdate> {
  @override
  final Iterable<Type> types = const [UserConfigUpdate, _$UserConfigUpdate];

  @override
  final String wireName = r'UserConfigUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserConfigUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.dataRetentionDays != null) {
      yield r'data_retention_days';
      yield serializers.serialize(
        object.dataRetentionDays,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.feishuWebhookUrl != null) {
      yield r'feishu_webhook_url';
      yield serializers.serialize(
        object.feishuWebhookUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserConfigUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserConfigUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'data_retention_days':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.dataRetentionDays = valueDes;
          break;
        case r'feishu_webhook_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  UserConfigUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserConfigUpdateBuilder();
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

