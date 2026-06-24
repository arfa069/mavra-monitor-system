//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'smart_home_entity.g.dart';

/// SmartHomeEntity
///
/// Properties:
/// * [domain] 
/// * [entityId] 
/// * [name] 
/// * [state] 
/// * [area] 
/// * [attributes] 
/// * [available] 
/// * [lastChanged] 
/// * [lastUpdated] 
@BuiltValue()
abstract class SmartHomeEntity implements Built<SmartHomeEntity, SmartHomeEntityBuilder> {
  @BuiltValueField(wireName: r'domain')
  SmartHomeEntityDomainEnum get domain;
  // enum domainEnum {  light,  switch,  fan,  cover,  climate,  scene,  script,  };

  @BuiltValueField(wireName: r'entity_id')
  String get entityId;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'state')
  String get state;

  @BuiltValueField(wireName: r'area')
  String? get area;

  @BuiltValueField(wireName: r'attributes')
  BuiltMap<String, JsonObject?>? get attributes;

  @BuiltValueField(wireName: r'available')
  bool? get available;

  @BuiltValueField(wireName: r'last_changed')
  DateTime? get lastChanged;

  @BuiltValueField(wireName: r'last_updated')
  DateTime? get lastUpdated;

  SmartHomeEntity._();

  factory SmartHomeEntity([void updates(SmartHomeEntityBuilder b)]) = _$SmartHomeEntity;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SmartHomeEntityBuilder b) => b
      ..available = true;

  @BuiltValueSerializer(custom: true)
  static Serializer<SmartHomeEntity> get serializer => _$SmartHomeEntitySerializer();
}

class _$SmartHomeEntitySerializer implements PrimitiveSerializer<SmartHomeEntity> {
  @override
  final Iterable<Type> types = const [SmartHomeEntity, _$SmartHomeEntity];

  @override
  final String wireName = r'SmartHomeEntity';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SmartHomeEntity object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'domain';
    yield serializers.serialize(
      object.domain,
      specifiedType: const FullType(SmartHomeEntityDomainEnum),
    );
    yield r'entity_id';
    yield serializers.serialize(
      object.entityId,
      specifiedType: const FullType(String),
    );
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    yield r'state';
    yield serializers.serialize(
      object.state,
      specifiedType: const FullType(String),
    );
    if (object.area != null) {
      yield r'area';
      yield serializers.serialize(
        object.area,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.attributes != null) {
      yield r'attributes';
      yield serializers.serialize(
        object.attributes,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
    if (object.available != null) {
      yield r'available';
      yield serializers.serialize(
        object.available,
        specifiedType: const FullType(bool),
      );
    }
    if (object.lastChanged != null) {
      yield r'last_changed';
      yield serializers.serialize(
        object.lastChanged,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.lastUpdated != null) {
      yield r'last_updated';
      yield serializers.serialize(
        object.lastUpdated,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeEntity object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SmartHomeEntityBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'domain':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(SmartHomeEntityDomainEnum),
          ) as SmartHomeEntityDomainEnum;
          result.domain = valueDes;
          break;
        case r'entity_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.entityId = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'state':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.state = valueDes;
          break;
        case r'area':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.area = valueDes;
          break;
        case r'attributes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
          result.attributes.replace(valueDes);
          break;
        case r'available':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.available = valueDes;
          break;
        case r'last_changed':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastChanged = valueDes;
          break;
        case r'last_updated':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.lastUpdated = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SmartHomeEntity deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SmartHomeEntityBuilder();
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

class SmartHomeEntityDomainEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'light')
  static const SmartHomeEntityDomainEnum light = _$smartHomeEntityDomainEnum_light;
  @BuiltValueEnumConst(wireName: r'switch')
  static const SmartHomeEntityDomainEnum switch_ = _$smartHomeEntityDomainEnum_switch_;
  @BuiltValueEnumConst(wireName: r'fan')
  static const SmartHomeEntityDomainEnum fan = _$smartHomeEntityDomainEnum_fan;
  @BuiltValueEnumConst(wireName: r'cover')
  static const SmartHomeEntityDomainEnum cover = _$smartHomeEntityDomainEnum_cover;
  @BuiltValueEnumConst(wireName: r'climate')
  static const SmartHomeEntityDomainEnum climate = _$smartHomeEntityDomainEnum_climate;
  @BuiltValueEnumConst(wireName: r'scene')
  static const SmartHomeEntityDomainEnum scene = _$smartHomeEntityDomainEnum_scene;
  @BuiltValueEnumConst(wireName: r'script')
  static const SmartHomeEntityDomainEnum script = _$smartHomeEntityDomainEnum_script;

  static Serializer<SmartHomeEntityDomainEnum> get serializer => _$smartHomeEntityDomainEnumSerializer;

  const SmartHomeEntityDomainEnum._(String name): super(name);

  static BuiltSet<SmartHomeEntityDomainEnum> get values => _$smartHomeEntityDomainEnumValues;
  static SmartHomeEntityDomainEnum valueOf(String name) => _$smartHomeEntityDomainEnumValueOf(name);
}

