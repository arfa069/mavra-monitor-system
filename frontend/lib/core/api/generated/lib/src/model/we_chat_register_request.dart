//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'we_chat_register_request.g.dart';

/// Request schema for registering an account from a WeChat callback.
///
/// Properties:
/// * [email] - 邮箱
/// * [password] - 密码
/// * [tempToken] 
/// * [username] - 用户名
@BuiltValue()
abstract class WeChatRegisterRequest implements Built<WeChatRegisterRequest, WeChatRegisterRequestBuilder> {
  /// 邮箱
  @BuiltValueField(wireName: r'email')
  String get email;

  /// 密码
  @BuiltValueField(wireName: r'password')
  String get password;

  @BuiltValueField(wireName: r'temp_token')
  String get tempToken;

  /// 用户名
  @BuiltValueField(wireName: r'username')
  String get username;

  WeChatRegisterRequest._();

  factory WeChatRegisterRequest([void updates(WeChatRegisterRequestBuilder b)]) = _$WeChatRegisterRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WeChatRegisterRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WeChatRegisterRequest> get serializer => _$WeChatRegisterRequestSerializer();
}

class _$WeChatRegisterRequestSerializer implements PrimitiveSerializer<WeChatRegisterRequest> {
  @override
  final Iterable<Type> types = const [WeChatRegisterRequest, _$WeChatRegisterRequest];

  @override
  final String wireName = r'WeChatRegisterRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WeChatRegisterRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'email';
    yield serializers.serialize(
      object.email,
      specifiedType: const FullType(String),
    );
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
    yield r'temp_token';
    yield serializers.serialize(
      object.tempToken,
      specifiedType: const FullType(String),
    );
    yield r'username';
    yield serializers.serialize(
      object.username,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    WeChatRegisterRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WeChatRegisterRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'email':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.email = valueDes;
          break;
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        case r'temp_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.tempToken = valueDes;
          break;
        case r'username':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.username = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  WeChatRegisterRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WeChatRegisterRequestBuilder();
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

