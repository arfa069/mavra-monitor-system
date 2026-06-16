//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'blog_post_create.g.dart';

/// BlogPostCreate
///
/// Properties:
/// * [title] 
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
@BuiltValue()
abstract class BlogPostCreate implements Built<BlogPostCreate, BlogPostCreateBuilder> {
  @BuiltValueField(wireName: r'title')
  String get title;

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
  BlogPostCreateStatusEnum? get status;
  // enum statusEnum {  draft,  scheduled,  published,  archived,  };

  @BuiltValueField(wireName: r'tag_ids')
  BuiltList<int>? get tagIds;

  @BuiltValueField(wireName: r'tag_names')
  BuiltList<String>? get tagNames;

  BlogPostCreate._();

  factory BlogPostCreate([void updates(BlogPostCreateBuilder b)]) = _$BlogPostCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BlogPostCreateBuilder b) => b
      ..contentHtml = ''
      ..status = BlogPostCreateStatusEnum.valueOf('draft');

  @BuiltValueSerializer(custom: true)
  static Serializer<BlogPostCreate> get serializer => _$BlogPostCreateSerializer();
}

class _$BlogPostCreateSerializer implements PrimitiveSerializer<BlogPostCreate> {
  @override
  final Iterable<Type> types = const [BlogPostCreate, _$BlogPostCreate];

  @override
  final String wireName = r'BlogPostCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BlogPostCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
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
        specifiedType: const FullType(String),
      );
    }
    if (object.contentJson != null) {
      yield r'content_json';
      yield serializers.serialize(
        object.contentJson,
        specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
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
        specifiedType: const FullType(BlogPostCreateStatusEnum),
      );
    }
    if (object.tagIds != null) {
      yield r'tag_ids';
      yield serializers.serialize(
        object.tagIds,
        specifiedType: const FullType(BuiltList, [FullType(int)]),
      );
    }
    if (object.tagNames != null) {
      yield r'tag_names';
      yield serializers.serialize(
        object.tagNames,
        specifiedType: const FullType(BuiltList, [FullType(String)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BlogPostCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BlogPostCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
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
            specifiedType: const FullType(String),
          ) as String;
          result.contentHtml = valueDes;
          break;
        case r'content_json':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
          ) as BuiltMap<String, JsonObject?>;
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
            specifiedType: const FullType(BlogPostCreateStatusEnum),
          ) as BlogPostCreateStatusEnum;
          result.status = valueDes;
          break;
        case r'tag_ids':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(int)]),
          ) as BuiltList<int>;
          result.tagIds.replace(valueDes);
          break;
        case r'tag_names':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.tagNames.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BlogPostCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BlogPostCreateBuilder();
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

class BlogPostCreateStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'draft')
  static const BlogPostCreateStatusEnum draft = _$blogPostCreateStatusEnum_draft;
  @BuiltValueEnumConst(wireName: r'scheduled')
  static const BlogPostCreateStatusEnum scheduled = _$blogPostCreateStatusEnum_scheduled;
  @BuiltValueEnumConst(wireName: r'published')
  static const BlogPostCreateStatusEnum published = _$blogPostCreateStatusEnum_published;
  @BuiltValueEnumConst(wireName: r'archived')
  static const BlogPostCreateStatusEnum archived = _$blogPostCreateStatusEnum_archived;

  static Serializer<BlogPostCreateStatusEnum> get serializer => _$blogPostCreateStatusEnumSerializer;

  const BlogPostCreateStatusEnum._(String name): super(name);

  static BuiltSet<BlogPostCreateStatusEnum> get values => _$blogPostCreateStatusEnumValues;
  static BlogPostCreateStatusEnum valueOf(String name) => _$blogPostCreateStatusEnumValueOf(name);
}

