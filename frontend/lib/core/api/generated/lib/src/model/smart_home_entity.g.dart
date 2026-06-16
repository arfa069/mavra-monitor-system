// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_home_entity.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_light =
    const SmartHomeEntityDomainEnum._('light');
const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_switch_ =
    const SmartHomeEntityDomainEnum._('switch_');
const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_fan =
    const SmartHomeEntityDomainEnum._('fan');
const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_cover =
    const SmartHomeEntityDomainEnum._('cover');
const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_climate =
    const SmartHomeEntityDomainEnum._('climate');
const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_scene =
    const SmartHomeEntityDomainEnum._('scene');
const SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnum_script =
    const SmartHomeEntityDomainEnum._('script');

SmartHomeEntityDomainEnum _$smartHomeEntityDomainEnumValueOf(String name) {
  switch (name) {
    case 'light':
      return _$smartHomeEntityDomainEnum_light;
    case 'switch_':
      return _$smartHomeEntityDomainEnum_switch_;
    case 'fan':
      return _$smartHomeEntityDomainEnum_fan;
    case 'cover':
      return _$smartHomeEntityDomainEnum_cover;
    case 'climate':
      return _$smartHomeEntityDomainEnum_climate;
    case 'scene':
      return _$smartHomeEntityDomainEnum_scene;
    case 'script':
      return _$smartHomeEntityDomainEnum_script;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<SmartHomeEntityDomainEnum> _$smartHomeEntityDomainEnumValues =
    BuiltSet<SmartHomeEntityDomainEnum>(const <SmartHomeEntityDomainEnum>[
      _$smartHomeEntityDomainEnum_light,
      _$smartHomeEntityDomainEnum_switch_,
      _$smartHomeEntityDomainEnum_fan,
      _$smartHomeEntityDomainEnum_cover,
      _$smartHomeEntityDomainEnum_climate,
      _$smartHomeEntityDomainEnum_scene,
      _$smartHomeEntityDomainEnum_script,
    ]);

Serializer<SmartHomeEntityDomainEnum> _$smartHomeEntityDomainEnumSerializer =
    _$SmartHomeEntityDomainEnumSerializer();

class _$SmartHomeEntityDomainEnumSerializer
    implements PrimitiveSerializer<SmartHomeEntityDomainEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'light': 'light',
    'switch_': 'switch',
    'fan': 'fan',
    'cover': 'cover',
    'climate': 'climate',
    'scene': 'scene',
    'script': 'script',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'light': 'light',
    'switch': 'switch_',
    'fan': 'fan',
    'cover': 'cover',
    'climate': 'climate',
    'scene': 'scene',
    'script': 'script',
  };

  @override
  final Iterable<Type> types = const <Type>[SmartHomeEntityDomainEnum];
  @override
  final String wireName = 'SmartHomeEntityDomainEnum';

  @override
  Object serialize(
    Serializers serializers,
    SmartHomeEntityDomainEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  SmartHomeEntityDomainEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => SmartHomeEntityDomainEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$SmartHomeEntity extends SmartHomeEntity {
  @override
  final SmartHomeEntityDomainEnum domain;
  @override
  final String entityId;
  @override
  final String name;
  @override
  final String state;
  @override
  final String? area;
  @override
  final BuiltMap<String, JsonObject?>? attributes;
  @override
  final bool? available;
  @override
  final DateTime? lastChanged;
  @override
  final DateTime? lastUpdated;

  factory _$SmartHomeEntity([void Function(SmartHomeEntityBuilder)? updates]) =>
      (SmartHomeEntityBuilder()..update(updates))._build();

  _$SmartHomeEntity._({
    required this.domain,
    required this.entityId,
    required this.name,
    required this.state,
    this.area,
    this.attributes,
    this.available,
    this.lastChanged,
    this.lastUpdated,
  }) : super._();
  @override
  SmartHomeEntity rebuild(void Function(SmartHomeEntityBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SmartHomeEntityBuilder toBuilder() => SmartHomeEntityBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SmartHomeEntity &&
        domain == other.domain &&
        entityId == other.entityId &&
        name == other.name &&
        state == other.state &&
        area == other.area &&
        attributes == other.attributes &&
        available == other.available &&
        lastChanged == other.lastChanged &&
        lastUpdated == other.lastUpdated;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, domain.hashCode);
    _$hash = $jc(_$hash, entityId.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, state.hashCode);
    _$hash = $jc(_$hash, area.hashCode);
    _$hash = $jc(_$hash, attributes.hashCode);
    _$hash = $jc(_$hash, available.hashCode);
    _$hash = $jc(_$hash, lastChanged.hashCode);
    _$hash = $jc(_$hash, lastUpdated.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SmartHomeEntity')
          ..add('domain', domain)
          ..add('entityId', entityId)
          ..add('name', name)
          ..add('state', state)
          ..add('area', area)
          ..add('attributes', attributes)
          ..add('available', available)
          ..add('lastChanged', lastChanged)
          ..add('lastUpdated', lastUpdated))
        .toString();
  }
}

class SmartHomeEntityBuilder
    implements Builder<SmartHomeEntity, SmartHomeEntityBuilder> {
  _$SmartHomeEntity? _$v;

  SmartHomeEntityDomainEnum? _domain;
  SmartHomeEntityDomainEnum? get domain => _$this._domain;
  set domain(SmartHomeEntityDomainEnum? domain) => _$this._domain = domain;

  String? _entityId;
  String? get entityId => _$this._entityId;
  set entityId(String? entityId) => _$this._entityId = entityId;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _state;
  String? get state => _$this._state;
  set state(String? state) => _$this._state = state;

  String? _area;
  String? get area => _$this._area;
  set area(String? area) => _$this._area = area;

  MapBuilder<String, JsonObject?>? _attributes;
  MapBuilder<String, JsonObject?> get attributes =>
      _$this._attributes ??= MapBuilder<String, JsonObject?>();
  set attributes(MapBuilder<String, JsonObject?>? attributes) =>
      _$this._attributes = attributes;

  bool? _available;
  bool? get available => _$this._available;
  set available(bool? available) => _$this._available = available;

  DateTime? _lastChanged;
  DateTime? get lastChanged => _$this._lastChanged;
  set lastChanged(DateTime? lastChanged) => _$this._lastChanged = lastChanged;

  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _$this._lastUpdated;
  set lastUpdated(DateTime? lastUpdated) => _$this._lastUpdated = lastUpdated;

  SmartHomeEntityBuilder() {
    SmartHomeEntity._defaults(this);
  }

  SmartHomeEntityBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _domain = $v.domain;
      _entityId = $v.entityId;
      _name = $v.name;
      _state = $v.state;
      _area = $v.area;
      _attributes = $v.attributes?.toBuilder();
      _available = $v.available;
      _lastChanged = $v.lastChanged;
      _lastUpdated = $v.lastUpdated;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SmartHomeEntity other) {
    _$v = other as _$SmartHomeEntity;
  }

  @override
  void update(void Function(SmartHomeEntityBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SmartHomeEntity build() => _build();

  _$SmartHomeEntity _build() {
    _$SmartHomeEntity _$result;
    try {
      _$result =
          _$v ??
          _$SmartHomeEntity._(
            domain: BuiltValueNullFieldError.checkNotNull(
              domain,
              r'SmartHomeEntity',
              'domain',
            ),
            entityId: BuiltValueNullFieldError.checkNotNull(
              entityId,
              r'SmartHomeEntity',
              'entityId',
            ),
            name: BuiltValueNullFieldError.checkNotNull(
              name,
              r'SmartHomeEntity',
              'name',
            ),
            state: BuiltValueNullFieldError.checkNotNull(
              state,
              r'SmartHomeEntity',
              'state',
            ),
            area: area,
            attributes: _attributes?.build(),
            available: available,
            lastChanged: lastChanged,
            lastUpdated: lastUpdated,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'attributes';
        _attributes?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'SmartHomeEntity',
          _$failedField,
          e.toString(),
        );
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
