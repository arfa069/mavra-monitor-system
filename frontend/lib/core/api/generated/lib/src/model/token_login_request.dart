//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/login_client_kind.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'token_login_request.g.dart';

/// Login request with explicit client token-storage mode.
///
/// Properties:
/// * [password] - 密码
/// * [username] - 用户名
/// * [clientKind] 
@BuiltValue()
abstract class TokenLoginRequest implements Built<TokenLoginRequest, TokenLoginRequestBuilder> {
  /// 密码
  @BuiltValueField(wireName: r'password')
  String get password;

  /// 用户名
  @BuiltValueField(wireName: r'username')
  String get username;

  @BuiltValueField(wireName: r'client_kind')
  LoginClientKind? get clientKind;
  // enum clientKindEnum {  web,  native,  };

  TokenLoginRequest._();

  factory TokenLoginRequest([void updates(TokenLoginRequestBuilder b)]) = _$TokenLoginRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(TokenLoginRequestBuilder b) => b
      ..clientKind = LoginClientKind.web;

  @BuiltValueSerializer(custom: true)
  static Serializer<TokenLoginRequest> get serializer => _$TokenLoginRequestSerializer();
}

class _$TokenLoginRequestSerializer implements PrimitiveSerializer<TokenLoginRequest> {
  @override
  final Iterable<Type> types = const [TokenLoginRequest, _$TokenLoginRequest];

  @override
  final String wireName = r'TokenLoginRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    TokenLoginRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
    yield r'username';
    yield serializers.serialize(
      object.username,
      specifiedType: const FullType(String),
    );
    if (object.clientKind != null) {
      yield r'client_kind';
      yield serializers.serialize(
        object.clientKind,
        specifiedType: const FullType(LoginClientKind),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    TokenLoginRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required TokenLoginRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.password = valueDes;
          break;
        case r'username':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.username = valueDes;
          break;
        case r'client_kind':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(LoginClientKind),
          ) as LoginClientKind;
          result.clientKind = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  TokenLoginRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = TokenLoginRequestBuilder();
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

