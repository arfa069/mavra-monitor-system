//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'blog_post_update.g.dart';

/// BlogPostUpdate
///
/// Properties:
/// * [canonicalUrl] 
/// * [categoryId] 
/// * [categoryName] 
/// * [contentHtml] 
/// * [contentJson] 
/// * [coverMediaId] 
/// * [coverUrl] 
/// * [excerpt] 
/// * [ogImageUrl] 
/// * [publishedAt] 
/// * [seoDescription] 
/// * [seoTitle] 
/// * [slug] 
/// * [status] 
/// * [tagIds] 
/// * [tagNames] 
/// * [title] 
@BuiltValue()
abstract class BlogPostUpdate implements Built<BlogPostUpdate, BlogPostUpdateBuilder> {
  @BuiltValueField(wireName: r'canonical_url')
  String? get canonicalUrl;

  @BuiltValueField(wireName: r'category_id')
  int? get categoryId;

  @BuiltValueField(wireName: r'category_name')
  String? get categoryName;

  @BuiltValueField(wireName: r'content_html')
  String? get contentHtml;

  @BuiltValueField(wireName: r'content_json')
  BuiltMap<String, JsonObject?>? get contentJson;

  @BuiltValueField(wireName: r'cover_media_id')
  int? get coverMediaId;

  @BuiltValueField(wireName: r'cover_url')
  String? get coverUrl;

  @BuiltValueField(wireName: r'excerpt')
  String? get excerpt;

  @BuiltValueField(wireName: r'og_image_url')
  String? get ogImageUrl;

  @BuiltValueField(wireName: r'published_at')
  DateTime? get publishedAt;

  @BuiltValueField(wireName: r'seo_description')
  String? get seoDescription;

  @BuiltValueField(wireName: r'seo_title')
  String? get seoTitle;

  @BuiltValueField(wireName: r'slug')
  String? get slug;

  @BuiltValueField(wireName: r'status')
  BlogPostUpdateStatusEnum? get status;
  // enum statusEnum {  draft,  scheduled,  published,  archived,  };

  @BuiltValueField(wireName: r'tag_ids')
  BuiltList<int>? get tagIds;

  @BuiltValueField(wireName: r'tag_names')
  BuiltList<String>? get tagNames;

  @BuiltValueField(wireName: r'title')
  String? get title;

  BlogPostUpdate._();

  factory BlogPostUpdate([void updates(BlogPostUpdateBuilder b)]) = _$BlogPostUpdate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BlogPostUpdateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BlogPostUpdate> get serializer => _$BlogPostUpdateSerializer();
}

class _$BlogPostUpdateSerializer implements PrimitiveSerializer<BlogPostUpdate> {
  @override
  final Iterable<Type> types = const [BlogPostUpdate, _$BlogPostUpdate];

  @override
  final String wireName = r'BlogPostUpdate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BlogPostUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.canonicalUrl != null) {
      yield r'canonical_url';
      yield serializers.serialize(
        object.canonicalUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.categoryId != null) {
      yield r'category_id';
      yield serializers.serialize(
        object.categoryId,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.categoryName != null) {
      yield r'category_name';
      yield serializers.serialize(
        object.categoryName,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.contentHtml != null) {
      yield r'content_html';
      yield serializers.serialize(
        object.contentHtml,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.contentJson != null) {
      yield r'content_json';
      yield serializers.serialize(
        object.contentJson,
        specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
      );
    }
    if (object.coverMediaId != null) {
      yield r'cover_media_id';
      yield serializers.serialize(
        object.coverMediaId,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.coverUrl != null) {
      yield r'cover_url';
      yield serializers.serialize(
        object.coverUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.excerpt != null) {
      yield r'excerpt';
      yield serializers.serialize(
        object.excerpt,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.ogImageUrl != null) {
      yield r'og_image_url';
      yield serializers.serialize(
        object.ogImageUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.publishedAt != null) {
      yield r'published_at';
      yield serializers.serialize(
        object.publishedAt,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.seoDescription != null) {
      yield r'seo_description';
      yield serializers.serialize(
        object.seoDescription,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.seoTitle != null) {
      yield r'seo_title';
      yield serializers.serialize(
        object.seoTitle,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.slug != null) {
      yield r'slug';
      yield serializers.serialize(
        object.slug,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.status != null) {
      yield r'status';
      yield serializers.serialize(
        object.status,
        specifiedType: const FullType.nullable(BlogPostUpdateStatusEnum),
      );
    }
    if (object.tagIds != null) {
      yield r'tag_ids';
      yield serializers.serialize(
        object.tagIds,
        specifiedType: const FullType.nullable(BuiltList, [FullType(int)]),
      );
    }
    if (object.tagNames != null) {
      yield r'tag_names';
      yield serializers.serialize(
        object.tagNames,
        specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
      );
    }
    if (object.title != null) {
      yield r'title';
      yield serializers.serialize(
        object.title,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BlogPostUpdate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BlogPostUpdateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'canonical_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.canonicalUrl = valueDes;
          break;
        case r'category_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.categoryId = valueDes;
          break;
        case r'category_name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categoryName = valueDes;
          break;
        case r'content_html':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.contentHtml = valueDes;
          break;
        case r'content_json':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>?;
          if (valueDes == null) continue;
          result.contentJson.replace(valueDes);
          break;
        case r'cover_media_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.coverMediaId = valueDes;
          break;
        case r'cover_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.coverUrl = valueDes;
          break;
        case r'excerpt':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.excerpt = valueDes;
          break;
        case r'og_image_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ogImageUrl = valueDes;
          break;
        case r'published_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.publishedAt = valueDes;
          break;
        case r'seo_description':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.seoDescription = valueDes;
          break;
        case r'seo_title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.seoTitle = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.slug = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BlogPostUpdateStatusEnum),
          ) as BlogPostUpdateStatusEnum?;
          if (valueDes == null) continue;
          result.status = valueDes;
          break;
        case r'tag_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(int)]),
          ) as BuiltList<int>?;
          if (valueDes == null) continue;
          result.tagIds.replace(valueDes);
          break;
        case r'tag_names':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BuiltList, [FullType(String)]),
          ) as BuiltList<String>?;
          if (valueDes == null) continue;
          result.tagNames.replace(valueDes);
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.title = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BlogPostUpdate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BlogPostUpdateBuilder();
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

class BlogPostUpdateStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'draft')
  static const BlogPostUpdateStatusEnum draft = _$blogPostUpdateStatusEnum_draft;
  @BuiltValueEnumConst(wireName: r'scheduled')
  static const BlogPostUpdateStatusEnum scheduled = _$blogPostUpdateStatusEnum_scheduled;
  @BuiltValueEnumConst(wireName: r'published')
  static const BlogPostUpdateStatusEnum published = _$blogPostUpdateStatusEnum_published;
  @BuiltValueEnumConst(wireName: r'archived')
  static const BlogPostUpdateStatusEnum archived = _$blogPostUpdateStatusEnum_archived;

  static Serializer<BlogPostUpdateStatusEnum> get serializer => _$blogPostUpdateStatusEnumSerializer;

  const BlogPostUpdateStatusEnum._(String name): super(name);

  static BuiltSet<BlogPostUpdateStatusEnum> get values => _$blogPostUpdateStatusEnumValues;
  static BlogPostUpdateStatusEnum valueOf(String name) => _$blogPostUpdateStatusEnumValueOf(name);
}

