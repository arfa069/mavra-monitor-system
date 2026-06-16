//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_resume_update.g.dart';

/// UserResumeUpdate
///
/// Properties:
/// * [name] 
/// * [resumeText] 
@BuiltValue()
abstract class UserResumeUpdate implements Built<UserResumeUpdate, UserResumeUpdateBuilder> {
  @BuiltValueField(wireName: r'name')
  String? get name;

  @BuiltValueField(wireName: r'resume_text')
  String? get resumeText;

  UserResumeUpdate._();

  factory UserResumeUpdate([void updates(UserResumeUpdateBuilder b)]) = _$UserResumeUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserResumeUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserResumeUpdate> get serializer => _$UserResumeUpdateSerializer();
}

class _$UserResumeUpdateSerializer implements PrimitiveSerializer<UserResumeUpdate> {
  @override
  final Iterable<Type> types = const [UserResumeUpdate, _$UserResumeUpdate];

  @override
  final String wireName = r'UserResumeUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserResumeUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.name != null) {
      yield r'name';
      yield serializers.serialize(
        object.name,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.resumeText != null) {
      yield r'resume_text';
      yield serializers.serialize(
        object.resumeText,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    UserResumeUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserResumeUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.name = valueDes;
          break;
        case r'resume_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resumeText = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  UserResumeUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserResumeUpdateBuilder();
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

