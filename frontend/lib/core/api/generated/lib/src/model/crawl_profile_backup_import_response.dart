//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_backup_import_response.g.dart';

/// CrawlProfileBackupImportResponse
///
/// Properties:
/// * [imported] 
/// * [profileKey] 
@BuiltValue()
abstract class CrawlProfileBackupImportResponse implements Built<CrawlProfileBackupImportResponse, CrawlProfileBackupImportResponseBuilder> {
  @BuiltValueField(wireName: r'imported')
  bool get imported;

  @BuiltValueField(wireName: r'profile_key')
  String get profileKey;

  CrawlProfileBackupImportResponse._();

  factory CrawlProfileBackupImportResponse([void updates(CrawlProfileBackupImportResponseBuilder b)]) = _$CrawlProfileBackupImportResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileBackupImportResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileBackupImportResponse> get serializer => _$CrawlProfileBackupImportResponseSerializer();
}

class _$CrawlProfileBackupImportResponseSerializer implements PrimitiveSerializer<CrawlProfileBackupImportResponse> {
  @override
  final Iterable<Type> types = const [CrawlProfileBackupImportResponse, _$CrawlProfileBackupImportResponse];

  @override
  final String wireName = r'CrawlProfileBackupImportResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileBackupImportResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'imported';
    yield serializers.serialize(
      object.imported,
      specifiedType: const FullType(bool),
    );
    yield r'profile_key';
    yield serializers.serialize(
      object.profileKey,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileBackupImportResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileBackupImportResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'imported':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.imported = valueDes;
          break;
        case r'profile_key':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.profileKey = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileBackupImportResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileBackupImportResponseBuilder();
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

