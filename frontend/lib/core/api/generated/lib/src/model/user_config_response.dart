//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_config_response.g.dart';

/// Schema for user configuration response.
///
/// Properties:
/// * [id] 
/// * [username] 
/// * [createdAt] 
/// * [dataRetentionDays] 
/// * [feishuWebhookUrl] 
/// * [updatedAt] 
@BuiltValue()
abstract class UserConfigResponse implements Built<UserConfigResponse, UserConfigResponseBuilder> {
  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'username')
  String get username;

  @BuiltValueField(wireName: r'created_at')
  DateTime? get createdAt;

  @BuiltValueField(wireName: r'data_retention_days')
  int? get dataRetentionDays;

  @BuiltValueField(wireName: r'feishu_webhook_url')
  String? get feishuWebhookUrl;

  @BuiltValueField(wireName: r'updated_at')
  DateTime? get updatedAt;

  UserConfigResponse._();

  factory UserConfigResponse([void updates(UserConfigResponseBuilder b)]) = _$UserConfigResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserConfigResponseBuilder b) => b
      ..dataRetentionDays = 365;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserConfigResponse> get serializer => _$UserConfigResponseSerializer();
}

class _$UserConfigResponseSerializer implements PrimitiveSerializer<UserConfigResponse> {
  @override
  final Iterable<Type> types = const [UserConfigResponse, _$UserConfigResponse];

  @override
  final String wireName = r'UserConfigResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserConfigResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'username';
    yield serializers.serialize(
      object.username,
      specifiedType: const FullType(String),
    );
    if (object.createdAt != null) {
      yield r'created_at';
      yield serializers.serialize(
        object.createdAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
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
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.updatedAt != null) {
      yield r'updated_at';
      yield serializers.serialize(
        object.updatedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserConfigResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserConfigResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'username':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.username = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.createdAt = valueDes;
          break;
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
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.feishuWebhookUrl = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
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
  UserConfigResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserConfigResponseBuilder();
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

