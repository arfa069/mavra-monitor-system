// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_post_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const BlogPostResponseStatusEnum _$blogPostResponseStatusEnum_draft =
    const BlogPostResponseStatusEnum._('draft');
const BlogPostResponseStatusEnum _$blogPostResponseStatusEnum_scheduled =
    const BlogPostResponseStatusEnum._('scheduled');
const BlogPostResponseStatusEnum _$blogPostResponseStatusEnum_published =
    const BlogPostResponseStatusEnum._('published');
const BlogPostResponseStatusEnum _$blogPostResponseStatusEnum_archived =
    const BlogPostResponseStatusEnum._('archived');

BlogPostResponseStatusEnum _$blogPostResponseStatusEnumValueOf(String name) {
  switch (name) {
    case 'draft':
      return _$blogPostResponseStatusEnum_draft;
    case 'scheduled':
      return _$blogPostResponseStatusEnum_scheduled;
    case 'published':
      return _$blogPostResponseStatusEnum_published;
    case 'archived':
      return _$blogPostResponseStatusEnum_archived;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<BlogPostResponseStatusEnum> _$blogPostResponseStatusEnumValues =
    BuiltSet<BlogPostResponseStatusEnum>(const <BlogPostResponseStatusEnum>[
      _$blogPostResponseStatusEnum_draft,
      _$blogPostResponseStatusEnum_scheduled,
      _$blogPostResponseStatusEnum_published,
      _$blogPostResponseStatusEnum_archived,
    ]);

Serializer<BlogPostResponseStatusEnum> _$blogPostResponseStatusEnumSerializer =
    _$BlogPostResponseStatusEnumSerializer();

class _$BlogPostResponseStatusEnumSerializer
    implements PrimitiveSerializer<BlogPostResponseStatusEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'draft': 'draft',
    'scheduled': 'scheduled',
    'published': 'published',
    'archived': 'archived',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'draft': 'draft',
    'scheduled': 'scheduled',
    'published': 'published',
    'archived': 'archived',
  };

  @override
  final Iterable<Type> types = const <Type>[BlogPostResponseStatusEnum];
  @override
  final String wireName = 'BlogPostResponseStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    BlogPostResponseStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  BlogPostResponseStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => BlogPostResponseStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$BlogPostResponse extends BlogPostResponse {
  @override
  final String contentHtml;
  @override
  final BuiltMap<String, JsonObject?> contentJson;
  @override
  final String contentText;
  @override
  final DateTime createdAt;
  @override
  final int id;
  @override
  final String slug;
  @override
  final BlogPostResponseStatusEnum status;
  @override
  final String title;
  @override
  final DateTime updatedAt;
  @override
  final String? canonicalUrl;
  @override
  final BlogCategoryResponse? category;
  @override
  final String? coverUrl;
  @override
  final String? excerpt;
  @override
  final String? ogImageUrl;
  @override
  final DateTime? publishedAt;
  @override
  final String? seoDescription;
  @override
  final String? seoTitle;
  @override
  final BuiltList<BlogTagResponse>? tags;

  factory _$BlogPostResponse([
    void Function(BlogPostResponseBuilder)? updates,
  ]) => (BlogPostResponseBuilder()..update(updates))._build();

  _$BlogPostResponse._({
    required this.contentHtml,
    required this.contentJson,
    required this.contentText,
    required this.createdAt,
    required this.id,
    required this.slug,
    required this.status,
    required this.title,
    required this.updatedAt,
    this.canonicalUrl,
    this.category,
    this.coverUrl,
    this.excerpt,
    this.ogImageUrl,
    this.publishedAt,
    this.seoDescription,
    this.seoTitle,
    this.tags,
  }) : super._();
  @override
  BlogPostResponse rebuild(void Function(BlogPostResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BlogPostResponseBuilder toBuilder() =>
      BlogPostResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogPostResponse &&
        contentHtml == other.contentHtml &&
        contentJson == other.contentJson &&
        contentText == other.contentText &&
        createdAt == other.createdAt &&
        id == other.id &&
        slug == other.slug &&
        status == other.status &&
        title == other.title &&
        updatedAt == other.updatedAt &&
        canonicalUrl == other.canonicalUrl &&
        category == other.category &&
        coverUrl == other.coverUrl &&
        excerpt == other.excerpt &&
        ogImageUrl == other.ogImageUrl &&
        publishedAt == other.publishedAt &&
        seoDescription == other.seoDescription &&
        seoTitle == other.seoTitle &&
        tags == other.tags;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contentHtml.hashCode);
    _$hash = $jc(_$hash, contentJson.hashCode);
    _$hash = $jc(_$hash, contentText.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, canonicalUrl.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, coverUrl.hashCode);
    _$hash = $jc(_$hash, excerpt.hashCode);
    _$hash = $jc(_$hash, ogImageUrl.hashCode);
    _$hash = $jc(_$hash, publishedAt.hashCode);
    _$hash = $jc(_$hash, seoDescription.hashCode);
    _$hash = $jc(_$hash, seoTitle.hashCode);
    _$hash = $jc(_$hash, tags.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogPostResponse')
          ..add('contentHtml', contentHtml)
          ..add('contentJson', contentJson)
          ..add('contentText', contentText)
          ..add('createdAt', createdAt)
          ..add('id', id)
          ..add('slug', slug)
          ..add('status', status)
          ..add('title', title)
          ..add('updatedAt', updatedAt)
          ..add('canonicalUrl', canonicalUrl)
          ..add('category', category)
          ..add('coverUrl', coverUrl)
          ..add('excerpt', excerpt)
          ..add('ogImageUrl', ogImageUrl)
          ..add('publishedAt', publishedAt)
          ..add('seoDescription', seoDescription)
          ..add('seoTitle', seoTitle)
          ..add('tags', tags))
        .toString();
  }
}

class BlogPostResponseBuilder
    implements Builder<BlogPostResponse, BlogPostResponseBuilder> {
  _$BlogPostResponse? _$v;

  String? _contentHtml;
  String? get contentHtml => _$this._contentHtml;
  set contentHtml(String? contentHtml) => _$this._contentHtml = contentHtml;

  MapBuilder<String, JsonObject?>? _contentJson;
  MapBuilder<String, JsonObject?> get contentJson =>
      _$this._contentJson ??= MapBuilder<String, JsonObject?>();
  set contentJson(MapBuilder<String, JsonObject?>? contentJson) =>
      _$this._contentJson = contentJson;

  String? _contentText;
  String? get contentText => _$this._contentText;
  set contentText(String? contentText) => _$this._contentText = contentText;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  BlogPostResponseStatusEnum? _status;
  BlogPostResponseStatusEnum? get status => _$this._status;
  set status(BlogPostResponseStatusEnum? status) => _$this._status = status;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

  String? _canonicalUrl;
  String? get canonicalUrl => _$this._canonicalUrl;
  set canonicalUrl(String? canonicalUrl) => _$this._canonicalUrl = canonicalUrl;

  BlogCategoryResponseBuilder? _category;
  BlogCategoryResponseBuilder get category =>
      _$this._category ??= BlogCategoryResponseBuilder();
  set category(BlogCategoryResponseBuilder? category) =>
      _$this._category = category;

  String? _coverUrl;
  String? get coverUrl => _$this._coverUrl;
  set coverUrl(String? coverUrl) => _$this._coverUrl = coverUrl;

  String? _excerpt;
  String? get excerpt => _$this._excerpt;
  set excerpt(String? excerpt) => _$this._excerpt = excerpt;

  String? _ogImageUrl;
  String? get ogImageUrl => _$this._ogImageUrl;
  set ogImageUrl(String? ogImageUrl) => _$this._ogImageUrl = ogImageUrl;

  DateTime? _publishedAt;
  DateTime? get publishedAt => _$this._publishedAt;
  set publishedAt(DateTime? publishedAt) => _$this._publishedAt = publishedAt;

  String? _seoDescription;
  String? get seoDescription => _$this._seoDescription;
  set seoDescription(String? seoDescription) =>
      _$this._seoDescription = seoDescription;

  String? _seoTitle;
  String? get seoTitle => _$this._seoTitle;
  set seoTitle(String? seoTitle) => _$this._seoTitle = seoTitle;

  ListBuilder<BlogTagResponse>? _tags;
  ListBuilder<BlogTagResponse> get tags =>
      _$this._tags ??= ListBuilder<BlogTagResponse>();
  set tags(ListBuilder<BlogTagResponse>? tags) => _$this._tags = tags;

  BlogPostResponseBuilder() {
    BlogPostResponse._defaults(this);
  }

  BlogPostResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contentHtml = $v.contentHtml;
      _contentJson = $v.contentJson.toBuilder();
      _contentText = $v.contentText;
      _createdAt = $v.createdAt;
      _id = $v.id;
      _slug = $v.slug;
      _status = $v.status;
      _title = $v.title;
      _updatedAt = $v.updatedAt;
      _canonicalUrl = $v.canonicalUrl;
      _category = $v.category?.toBuilder();
      _coverUrl = $v.coverUrl;
      _excerpt = $v.excerpt;
      _ogImageUrl = $v.ogImageUrl;
      _publishedAt = $v.publishedAt;
      _seoDescription = $v.seoDescription;
      _seoTitle = $v.seoTitle;
      _tags = $v.tags?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogPostResponse other) {
    _$v = other as _$BlogPostResponse;
  }

  @override
  void update(void Function(BlogPostResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogPostResponse build() => _build();

  _$BlogPostResponse _build() {
    _$BlogPostResponse _$result;
    try {
      _$result =
          _$v ??
          _$BlogPostResponse._(
            contentHtml: BuiltValueNullFieldError.checkNotNull(
              contentHtml,
              r'BlogPostResponse',
              'contentHtml',
            ),
            contentJson: contentJson.build(),
            contentText: BuiltValueNullFieldError.checkNotNull(
              contentText,
              r'BlogPostResponse',
              'contentText',
            ),
            createdAt: BuiltValueNullFieldError.checkNotNull(
              createdAt,
              r'BlogPostResponse',
              'createdAt',
            ),
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'BlogPostResponse',
              'id',
            ),
            slug: BuiltValueNullFieldError.checkNotNull(
              slug,
              r'BlogPostResponse',
              'slug',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'BlogPostResponse',
              'status',
            ),
            title: BuiltValueNullFieldError.checkNotNull(
              title,
              r'BlogPostResponse',
              'title',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'BlogPostResponse',
              'updatedAt',
            ),
            canonicalUrl: canonicalUrl,
            category: _category?.build(),
            coverUrl: coverUrl,
            excerpt: excerpt,
            ogImageUrl: ogImageUrl,
            publishedAt: publishedAt,
            seoDescription: seoDescription,
            seoTitle: seoTitle,
            tags: _tags?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'contentJson';
        contentJson.build();

        _$failedField = 'category';
        _category?.build();

        _$failedField = 'tags';
        _tags?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BlogPostResponse',
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
