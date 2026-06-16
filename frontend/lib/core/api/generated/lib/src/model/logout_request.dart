//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'logout_request.g.dart';

/// Optional native refresh token used to identify the session.
///
/// Properties:
/// * [refreshToken] 
@BuiltValue()
abstract class LogoutRequest implements Built<LogoutRequest, LogoutRequestBuilder> {
  @BuiltValueField(wireName: r'refresh_token')
  String? get refreshToken;

  LogoutRequest._();

  factory LogoutRequest([void updates(LogoutRequestBuilder b)]) = _$LogoutRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LogoutRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LogoutRequest> get serializer => _$LogoutRequestSerializer();
}

class _$LogoutRequestSerializer implements PrimitiveSerializer<LogoutRequest> {
  @override
  final Iterable<Type> types = const [LogoutRequest, _$LogoutRequest];

  @override
  final String wireName = r'LogoutRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LogoutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
    LogoutRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LogoutRequestBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
  LogoutRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LogoutRequestBuilder();
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

