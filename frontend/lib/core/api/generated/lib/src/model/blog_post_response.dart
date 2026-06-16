//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/blog_tag_response.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/blog_category_response.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'blog_post_response.g.dart';

/// BlogPostResponse
///
/// Properties:
/// * [contentHtml] 
/// * [contentJson] 
/// * [contentText] 
/// * [createdAt] 
/// * [id] 
/// * [slug] 
/// * [status] 
/// * [title] 
/// * [updatedAt] 
/// * [canonicalUrl] 
/// * [category] 
/// * [coverUrl] 
/// * [excerpt] 
/// * [ogImageUrl] 
/// * [publishedAt] 
/// * [seoDescription] 
/// * [seoTitle] 
/// * [tags] 
@BuiltValue()
abstract class BlogPostResponse implements Built<BlogPostResponse, BlogPostResponseBuilder> {
  @BuiltValueField(wireName: r'content_html')
  String get contentHtml;

  @BuiltValueField(wireName: r'content_json')
  BuiltMap<String, JsonObject?> get contentJson;

  @BuiltValueField(wireName: r'content_text')
  String get contentText;

  @BuiltValueField(wireName: r'created_at')
  DateTime get createdAt;

  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'status')
  BlogPostResponseStatusEnum get status;
  // enum statusEnum {  draft,  scheduled,  published,  archived,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'canonical_url')
  String? get canonicalUrl;

  @BuiltValueField(wireName: r'category')
  BlogCategoryResponse? get category;

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

  @BuiltValueField(wireName: r'tags')
  BuiltList<BlogTagResponse>? get tags;

  BlogPostResponse._();

  factory BlogPostResponse([void updates(BlogPostResponseBuilder b)]) = _$BlogPostResponse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BlogPostResponseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BlogPostResponse> get serializer => _$BlogPostResponseSerializer();
}

class _$BlogPostResponseSerializer implements PrimitiveSerializer<BlogPostResponse> {
  @override
  final Iterable<Type> types = const [BlogPostResponse, _$BlogPostResponse];

  @override
  final String wireName = r'BlogPostResponse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BlogPostResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'content_html';
    yield serializers.serialize(
      object.contentHtml,
      specifiedType: const FullType(String),
    );
    yield r'content_json';
    yield serializers.serialize(
      object.contentJson,
      specifiedType: const FullType(BuiltMap, [FullType(String), FullType.nullable(JsonObject)]),
    );
    yield r'content_text';
    yield serializers.serialize(
      object.contentText,
      specifiedType: const FullType(String),
    );
    yield r'created_at';
    yield serializers.serialize(
      object.createdAt,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(int),
    );
    yield r'slug';
    yield serializers.serialize(
      object.slug,
      specifiedType: const FullType(String),
    );
    yield r'status';
    yield serializers.serialize(
      object.status,
      specifiedType: const FullType(BlogPostResponseStatusEnum),
    );
    yield r'title';
    yield serializers.serialize(
      object.title,
      specifiedType: const FullType(String),
    );
    yield r'updated_at';
    yield serializers.serialize(
      object.updatedAt,
      specifiedType: const FullType(DateTime),
    );
    if (object.canonicalUrl != null) {
      yield r'canonical_url';
      yield serializers.serialize(
        object.canonicalUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.category != null) {
      yield r'category';
      yield serializers.serialize(
        object.category,
        specifiedType: const FullType.nullable(BlogCategoryResponse),
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
    if (object.tags != null) {
      yield r'tags';
      yield serializers.serialize(
        object.tags,
        specifiedType: const FullType(BuiltList, [FullType(BlogTagResponse)]),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    BlogPostResponse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BlogPostResponseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
        case r'content_text':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.contentText = valueDes;
          break;
        case r'created_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.createdAt = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.slug = valueDes;
          break;
        case r'status':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BlogPostResponseStatusEnum),
          ) as BlogPostResponseStatusEnum;
          result.status = valueDes;
          break;
        case r'title':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.title = valueDes;
          break;
        case r'updated_at':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.updatedAt = valueDes;
          break;
        case r'canonical_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.canonicalUrl = valueDes;
          break;
        case r'category':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(BlogCategoryResponse),
          ) as BlogCategoryResponse?;
          if (valueDes == null) continue;
          result.category.replace(valueDes);
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
        case r'tags':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(BlogTagResponse)]),
          ) as BuiltList<BlogTagResponse>;
          result.tags.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BlogPostResponse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BlogPostResponseBuilder();
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

class BlogPostResponseStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'draft')
  static const BlogPostResponseStatusEnum draft = _$blogPostResponseStatusEnum_draft;
  @BuiltValueEnumConst(wireName: r'scheduled')
  static const BlogPostResponseStatusEnum scheduled = _$blogPostResponseStatusEnum_scheduled;
  @BuiltValueEnumConst(wireName: r'published')
  static const BlogPostResponseStatusEnum published = _$blogPostResponseStatusEnum_published;
  @BuiltValueEnumConst(wireName: r'archived')
  static const BlogPostResponseStatusEnum archived = _$blogPostResponseStatusEnum_archived;

  static Serializer<BlogPostResponseStatusEnum> get serializer => _$blogPostResponseStatusEnumSerializer;

  const BlogPostResponseStatusEnum._(String name): super(name);

  static BuiltSet<BlogPostResponseStatusEnum> get values => _$blogPostResponseStatusEnumValues;
  static BlogPostResponseStatusEnum valueOf(String name) => _$blogPostResponseStatusEnumValueOf(name);
}

