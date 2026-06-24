//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mavra_api/src/model/blog_tag_response.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mavra_api/src/model/blog_category_response.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'blog_post_list_item.g.dart';

/// BlogPostListItem
///
/// Properties:
/// * [id] 
/// * [slug] 
/// * [status] 
/// * [title] 
/// * [updatedAt] 
/// * [category] 
/// * [coverUrl] 
/// * [excerpt] 
/// * [publishedAt] 
/// * [seoDescription] 
/// * [seoTitle] 
/// * [tags] 
@BuiltValue()
abstract class BlogPostListItem implements Built<BlogPostListItem, BlogPostListItemBuilder> {
  @BuiltValueField(wireName: r'id')
  int get id;

  @BuiltValueField(wireName: r'slug')
  String get slug;

  @BuiltValueField(wireName: r'status')
  BlogPostListItemStatusEnum get status;
  // enum statusEnum {  draft,  scheduled,  published,  archived,  };

  @BuiltValueField(wireName: r'title')
  String get title;

  @BuiltValueField(wireName: r'updated_at')
  DateTime get updatedAt;

  @BuiltValueField(wireName: r'category')
  BlogCategoryResponse? get category;

  @BuiltValueField(wireName: r'cover_url')
  String? get coverUrl;

  @BuiltValueField(wireName: r'excerpt')
  String? get excerpt;

  @BuiltValueField(wireName: r'published_at')
  DateTime? get publishedAt;

  @BuiltValueField(wireName: r'seo_description')
  String? get seoDescription;

  @BuiltValueField(wireName: r'seo_title')
  String? get seoTitle;

  @BuiltValueField(wireName: r'tags')
  BuiltList<BlogTagResponse>? get tags;

  BlogPostListItem._();

  factory BlogPostListItem([void updates(BlogPostListItemBuilder b)]) = _$BlogPostListItem;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BlogPostListItemBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BlogPostListItem> get serializer => _$BlogPostListItemSerializer();
}

class _$BlogPostListItemSerializer implements PrimitiveSerializer<BlogPostListItem> {
  @override
  final Iterable<Type> types = const [BlogPostListItem, _$BlogPostListItem];

  @override
  final String wireName = r'BlogPostListItem';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BlogPostListItem object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
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
      specifiedType: const FullType(BlogPostListItemStatusEnum),
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
    BlogPostListItem object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BlogPostListItemBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
            specifiedType: const FullType(BlogPostListItemStatusEnum),
          ) as BlogPostListItemStatusEnum;
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
  BlogPostListItem deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BlogPostListItemBuilder();
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

class BlogPostListItemStatusEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'draft')
  static const BlogPostListItemStatusEnum draft = _$blogPostListItemStatusEnum_draft;
  @BuiltValueEnumConst(wireName: r'scheduled')
  static const BlogPostListItemStatusEnum scheduled = _$blogPostListItemStatusEnum_scheduled;
  @BuiltValueEnumConst(wireName: r'published')
  static const BlogPostListItemStatusEnum published = _$blogPostListItemStatusEnum_published;
  @BuiltValueEnumConst(wireName: r'archived')
  static const BlogPostListItemStatusEnum archived = _$blogPostListItemStatusEnum_archived;

  static Serializer<BlogPostListItemStatusEnum> get serializer => _$blogPostListItemStatusEnumSerializer;

  const BlogPostListItemStatusEnum._(String name): super(name);

  static BuiltSet<BlogPostListItemStatusEnum> get values => _$blogPostListItemStatusEnumValues;
  static BlogPostListItemStatusEnum valueOf(String name) => _$blogPostListItemStatusEnumValueOf(name);
}

