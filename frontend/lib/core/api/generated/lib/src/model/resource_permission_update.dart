//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resource_permission_update.g.dart';

/// Schema for updating an existing resource permission.
///
/// Properties:
/// * [permission] 
/// * [resourceId] 
/// * [resourceType] 
@BuiltValue()
abstract class ResourcePermissionUpdate implements Built<ResourcePermissionUpdate, ResourcePermissionUpdateBuilder> {
  @BuiltValueField(wireName: r'permission')
  String? get permission;

  @BuiltValueField(wireName: r'resource_id')
  String? get resourceId;

  @BuiltValueField(wireName: r'resource_type')
  String? get resourceType;

  ResourcePermissionUpdate._();

  factory ResourcePermissionUpdate([void updates(ResourcePermissionUpdateBuilder b)]) = _$ResourcePermissionUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResourcePermissionUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResourcePermissionUpdate> get serializer => _$ResourcePermissionUpdateSerializer();
}

class _$ResourcePermissionUpdateSerializer implements PrimitiveSerializer<ResourcePermissionUpdate> {
  @override
  final Iterable<Type> types = const [ResourcePermissionUpdate, _$ResourcePermissionUpdate];

  @override
  final String wireName = r'ResourcePermissionUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResourcePermissionUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.permission != null) {
      yield r'permission';
      yield serializers.serialize(
        object.permission,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.resourceId != null) {
      yield r'resource_id';
      yield serializers.serialize(
        object.resourceId,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.resourceType != null) {
      yield r'resource_type';
      yield serializers.serialize(
        object.resourceType,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ResourcePermissionUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResourcePermissionUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.permission = valueDes;
          break;
        case r'resource_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resourceId = valueDes;
          break;
        case r'resource_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resourceType = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResourcePermissionUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResourcePermissionUpdateBuilder();
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

