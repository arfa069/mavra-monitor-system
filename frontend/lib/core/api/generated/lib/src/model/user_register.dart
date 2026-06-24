//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_register.g.dart';

/// Request schema for user registration.
///
/// Properties:
/// * [email] - 邮箱
/// * [password] - 密码
/// * [username] - 用户名
@BuiltValue()
abstract class UserRegister implements Built<UserRegister, UserRegisterBuilder> {
  /// 邮箱
  @BuiltValueField(wireName: r'email')
  String get email;

  /// 密码
  @BuiltValueField(wireName: r'password')
  String get password;

  /// 用户名
  @BuiltValueField(wireName: r'username')
  String get username;

  UserRegister._();

  factory UserRegister([void updates(UserRegisterBuilder b)]) = _$UserRegister;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserRegisterBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserRegister> get serializer => _$UserRegisterSerializer();
}

class _$UserRegisterSerializer implements PrimitiveSerializer<UserRegister> {
  @override
  final Iterable<Type> types = const [UserRegister, _$UserRegister];

  @override
  final String wireName = r'UserRegister';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserRegister object, {
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
    yield r'username';
    yield serializers.serialize(
      object.username,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UserRegister object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserRegisterBuilder result,
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
  UserRegister deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserRegisterBuilder();
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

