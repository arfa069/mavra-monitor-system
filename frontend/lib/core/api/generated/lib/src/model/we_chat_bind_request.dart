//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'we_chat_bind_request.g.dart';

/// Request schema for binding WeChat to an existing account.
///
/// Properties:
/// * [password] 
/// * [tempToken] 
/// * [username] 
@BuiltValue()
abstract class WeChatBindRequest implements Built<WeChatBindRequest, WeChatBindRequestBuilder> {
  @BuiltValueField(wireName: r'password')
  String get password;

  @BuiltValueField(wireName: r'temp_token')
  String get tempToken;

  @BuiltValueField(wireName: r'username')
  String get username;

  WeChatBindRequest._();

  factory WeChatBindRequest([void updates(WeChatBindRequestBuilder b)]) = _$WeChatBindRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(WeChatBindRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<WeChatBindRequest> get serializer => _$WeChatBindRequestSerializer();
}

class _$WeChatBindRequestSerializer implements PrimitiveSerializer<WeChatBindRequest> {
  @override
  final Iterable<Type> types = const [WeChatBindRequest, _$WeChatBindRequest];

  @override
  final String wireName = r'WeChatBindRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    WeChatBindRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    WeChatBindRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required WeChatBindRequestBuilder result,
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
  WeChatBindRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = WeChatBindRequestBuilder();
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

