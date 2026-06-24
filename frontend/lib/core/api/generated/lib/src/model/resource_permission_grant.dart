//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resource_permission_grant.g.dart';

/// Schema for granting resource permissions.
///
/// Properties:
/// * [permission] 
/// * [resourceIds] - 资源 ID 列表，支持 '*' 表示全部
/// * [resourceType] 
/// * [subjectId] - 被授权用户 ID
@BuiltValue()
abstract class ResourcePermissionGrant implements Built<ResourcePermissionGrant, ResourcePermissionGrantBuilder> {
  @BuiltValueField(wireName: r'permission')
  String get permission;

  /// 资源 ID 列表，支持 '*' 表示全部
  @BuiltValueField(wireName: r'resource_ids')
  BuiltList<String> get resourceIds;

  @BuiltValueField(wireName: r'resource_type')
  String get resourceType;

  /// 被授权用户 ID
  @BuiltValueField(wireName: r'subject_id')
  int get subjectId;

  ResourcePermissionGrant._();

  factory ResourcePermissionGrant([void updates(ResourcePermissionGrantBuilder b)]) = _$ResourcePermissionGrant;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResourcePermissionGrantBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResourcePermissionGrant> get serializer => _$ResourcePermissionGrantSerializer();
}

class _$ResourcePermissionGrantSerializer implements PrimitiveSerializer<ResourcePermissionGrant> {
  @override
  final Iterable<Type> types = const [ResourcePermissionGrant, _$ResourcePermissionGrant];

  @override
  final String wireName = r'ResourcePermissionGrant';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResourcePermissionGrant object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'permission';
    yield serializers.serialize(
      object.permission,
      specifiedType: const FullType(String),
    );
    yield r'resource_ids';
    yield serializers.serialize(
      object.resourceIds,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    yield r'resource_type';
    yield serializers.serialize(
      object.resourceType,
      specifiedType: const FullType(String),
    );
    yield r'subject_id';
    yield serializers.serialize(
      object.subjectId,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResourcePermissionGrant object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResourcePermissionGrantBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'permission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.permission = valueDes;
          break;
        case r'resource_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.resourceIds.replace(valueDes);
          break;
        case r'resource_type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.resourceType = valueDes;
          break;
        case r'subject_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.subjectId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResourcePermissionGrant deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResourcePermissionGrantBuilder();
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

