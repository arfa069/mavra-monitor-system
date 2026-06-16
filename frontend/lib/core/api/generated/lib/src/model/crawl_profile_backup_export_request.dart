//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'crawl_profile_backup_export_request.g.dart';

/// CrawlProfileBackupExportRequest
///
/// Properties:
/// * [password] 
@BuiltValue()
abstract class CrawlProfileBackupExportRequest implements Built<CrawlProfileBackupExportRequest, CrawlProfileBackupExportRequestBuilder> {
  @BuiltValueField(wireName: r'password')
  String get password;

  CrawlProfileBackupExportRequest._();

  factory CrawlProfileBackupExportRequest([void updates(CrawlProfileBackupExportRequestBuilder b)]) = _$CrawlProfileBackupExportRequest;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CrawlProfileBackupExportRequestBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CrawlProfileBackupExportRequest> get serializer => _$CrawlProfileBackupExportRequestSerializer();
}

class _$CrawlProfileBackupExportRequestSerializer implements PrimitiveSerializer<CrawlProfileBackupExportRequest> {
  @override
  final Iterable<Type> types = const [CrawlProfileBackupExportRequest, _$CrawlProfileBackupExportRequest];

  @override
  final String wireName = r'CrawlProfileBackupExportRequest';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CrawlProfileBackupExportRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'password';
    yield serializers.serialize(
      object.password,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CrawlProfileBackupExportRequest object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CrawlProfileBackupExportRequestBuilder result,
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CrawlProfileBackupExportRequest deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CrawlProfileBackupExportRequestBuilder();
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

