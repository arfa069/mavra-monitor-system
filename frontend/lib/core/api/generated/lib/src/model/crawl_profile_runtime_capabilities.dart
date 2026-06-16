//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_runtime_capabilities.g.dart';

/// CrawlProfileRuntimeCapabilities
///
/// Properties:
/// * [mode] 
/// * [os] 
/// * [recommendedAction] 
/// * [supportsLoginSession] 
/// * [supportsProfileExport] 
/// * [supportsProfileImport] 
@BuiltValue()
abstract class CrawlProfileRuntimeCapabilities implements Built<CrawlProfileRuntimeCapabilities, CrawlProfileRuntimeCapabilitiesBuilder> {
  @BuiltValueField(wireName: r'mode')
  CrawlProfileRuntimeCapabilitiesModeEnum get mode;
  // enum modeEnum {  local_gui,  headless_server,  };

  @BuiltValueField(wireName: r'os')
  String get os;

  @BuiltValueField(wireName: r'recommended_action')
  CrawlProfileRuntimeCapabilitiesRecommendedActionEnum get recommendedAction;
  // enum recommendedActionEnum {  open_login_browser,  import_profile_backup,  };

  @BuiltValueField(wireName: r'supports_login_session')
  bool get supportsLoginSession;

  @BuiltValueField(wireName: r'supports_profile_export')
  bool get supportsProfileExport;

  @BuiltValueField(wireName: r'supports_profile_import')
  bool get supportsProfileImport;

  CrawlProfileRuntimeCapabilities._();

  factory CrawlProfileRuntimeCapabilities([void updates(CrawlProfileRuntimeCapabilitiesBuilder b)]) = _$CrawlProfileRuntimeCapabilities;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileRuntimeCapabilitiesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileRuntimeCapabilities> get serializer => _$CrawlProfileRuntimeCapabilitiesSerializer();
}

class _$CrawlProfileRuntimeCapabilitiesSerializer implements PrimitiveSerializer<CrawlProfileRuntimeCapabilities> {
  @override
  final Iterable<Type> types = const [CrawlProfileRuntimeCapabilities, _$CrawlProfileRuntimeCapabilities];

  @override
  final String wireName = r'CrawlProfileRuntimeCapabilities';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileRuntimeCapabilities object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'mode';
    yield serializers.serialize(
      object.mode,
      specifiedType: const FullType(CrawlProfileRuntimeCapabilitiesModeEnum),
    );
    yield r'os';
    yield serializers.serialize(
      object.os,
      specifiedType: const FullType(String),
    );
    yield r'recommended_action';
    yield serializers.serialize(
      object.recommendedAction,
      specifiedType: const FullType(CrawlProfileRuntimeCapabilitiesRecommendedActionEnum),
    );
    yield r'supports_login_session';
    yield serializers.serialize(
      object.supportsLoginSession,
      specifiedType: const FullType(bool),
    );
    yield r'supports_profile_export';
    yield serializers.serialize(
      object.supportsProfileExport,
      specifiedType: const FullType(bool),
    );
    yield r'supports_profile_import';
    yield serializers.serialize(
      object.supportsProfileImport,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileRuntimeCapabilities object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileRuntimeCapabilitiesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'mode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CrawlProfileRuntimeCapabilitiesModeEnum),
          ) as CrawlProfileRuntimeCapabilitiesModeEnum;
          result.mode = valueDes;
          break;
        case r'os':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.os = valueDes;
          break;
        case r'recommended_action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CrawlProfileRuntimeCapabilitiesRecommendedActionEnum),
          ) as CrawlProfileRuntimeCapabilitiesRecommendedActionEnum;
          result.recommendedAction = valueDes;
          break;
        case r'supports_login_session':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.supportsLoginSession = valueDes;
          break;
        case r'supports_profile_export':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.supportsProfileExport = valueDes;
          break;
        case r'supports_profile_import':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.supportsProfileImport = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileRuntimeCapabilities deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileRuntimeCapabilitiesBuilder();
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

class CrawlProfileRuntimeCapabilitiesModeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'local_gui')
  static const CrawlProfileRuntimeCapabilitiesModeEnum localGui = _$crawlProfileRuntimeCapabilitiesModeEnum_localGui;
  @BuiltValueEnumConst(wireName: r'headless_server')
  static const CrawlProfileRuntimeCapabilitiesModeEnum headlessServer = _$crawlProfileRuntimeCapabilitiesModeEnum_headlessServer;

  static Serializer<CrawlProfileRuntimeCapabilitiesModeEnum> get serializer => _$crawlProfileRuntimeCapabilitiesModeEnumSerializer;

  const CrawlProfileRuntimeCapabilitiesModeEnum._(String name): super(name);

  static BuiltSet<CrawlProfileRuntimeCapabilitiesModeEnum> get values => _$crawlProfileRuntimeCapabilitiesModeEnumValues;
  static CrawlProfileRuntimeCapabilitiesModeEnum valueOf(String name) => _$crawlProfileRuntimeCapabilitiesModeEnumValueOf(name);
}

class CrawlProfileRuntimeCapabilitiesRecommendedActionEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'open_login_browser')
  static const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum openLoginBrowser = _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_openLoginBrowser;
  @BuiltValueEnumConst(wireName: r'import_profile_backup')
  static const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum importProfileBackup = _$crawlProfileRuntimeCapabilitiesRecommendedActionEnum_importProfileBackup;

  static Serializer<CrawlProfileRuntimeCapabilitiesRecommendedActionEnum> get serializer => _$crawlProfileRuntimeCapabilitiesRecommendedActionEnumSerializer;

  const CrawlProfileRuntimeCapabilitiesRecommendedActionEnum._(String name): super(name);

  static BuiltSet<CrawlProfileRuntimeCapabilitiesRecommendedActionEnum> get values => _$crawlProfileRuntimeCapabilitiesRecommendedActionEnumValues;
  static CrawlProfileRuntimeCapabilitiesRecommendedActionEnum valueOf(String name) => _$crawlProfileRuntimeCapabilitiesRecommendedActionEnumValueOf(name);
}

