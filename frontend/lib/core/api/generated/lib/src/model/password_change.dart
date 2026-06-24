//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'password_change.g.dart';

/// Schema for password change.
///
/// Properties:
/// * [newPassword] 
/// * [oldPassword] 
/// * [refreshToken] 
@BuiltValue()
abstract class PasswordChange implements Built<PasswordChange, PasswordChangeBuilder> {
  @BuiltValueField(wireName: r'new_password')
  String get newPassword;

  @BuiltValueField(wireName: r'old_password')
  String get oldPassword;

  @BuiltValueField(wireName: r'refresh_token')
  String? get refreshToken;

  PasswordChange._();

  factory PasswordChange([void updates(PasswordChangeBuilder b)]) = _$PasswordChange;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PasswordChangeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PasswordChange> get serializer => _$PasswordChangeSerializer();
}

class _$PasswordChangeSerializer implements PrimitiveSerializer<PasswordChange> {
  @override
  final Iterable<Type> types = const [PasswordChange, _$PasswordChange];

  @override
  final String wireName = r'PasswordChange';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PasswordChange object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'new_password';
    yield serializers.serialize(
      object.newPassword,
      specifiedType: const FullType(String),
    );
    yield r'old_password';
    yield serializers.serialize(
      object.oldPassword,
      specifiedType: const FullType(String),
    );
    if (object.refreshToken != null) {
      yield r'refresh_token';
      yield serializers.serialize(
        object.refreshToken,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    PasswordChange object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PasswordChangeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'new_password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.newPassword = valueDes;
          break;
        case r'old_password':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.oldPassword = valueDes;
          break;
        case r'refresh_token':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.refreshToken = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  PasswordChange deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PasswordChangeBuilder();
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

