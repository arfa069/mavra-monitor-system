//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'user_resume_create.g.dart';

/// UserResumeCreate
///
/// Properties:
/// * [name] 
/// * [resumeText] 
@BuiltValue()
abstract class UserResumeCreate implements Built<UserResumeCreate, UserResumeCreateBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'resume_text')
  String get resumeText;

  UserResumeCreate._();

  factory UserResumeCreate([void updates(UserResumeCreateBuilder b)]) = _$UserResumeCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(UserResumeCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<UserResumeCreate> get serializer => _$UserResumeCreateSerializer();
}

class _$UserResumeCreateSerializer implements PrimitiveSerializer<UserResumeCreate> {
  @override
  final Iterable<Type> types = const [UserResumeCreate, _$UserResumeCreate];

  @override
  final String wireName = r'UserResumeCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    UserResumeCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'resume_text';
    yield serializers.serialize(
      object.resumeText,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    UserResumeCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required UserResumeCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'resume_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  UserResumeCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = UserResumeCreateBuilder();
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

