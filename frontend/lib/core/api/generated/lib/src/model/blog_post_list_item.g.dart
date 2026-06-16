// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_post_list_item.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const BlogPostListItemStatusEnum _$blogPostListItemStatusEnum_draft =
    const BlogPostListItemStatusEnum._('draft');
const BlogPostListItemStatusEnum _$blogPostListItemStatusEnum_scheduled =
    const BlogPostListItemStatusEnum._('scheduled');
const BlogPostListItemStatusEnum _$blogPostListItemStatusEnum_published =
    const BlogPostListItemStatusEnum._('published');
const BlogPostListItemStatusEnum _$blogPostListItemStatusEnum_archived =
    const BlogPostListItemStatusEnum._('archived');

BlogPostListItemStatusEnum _$blogPostListItemStatusEnumValueOf(String name) {
  switch (name) {
    case 'draft':
      return _$blogPostListItemStatusEnum_draft;
    case 'scheduled':
      return _$blogPostListItemStatusEnum_scheduled;
    case 'published':
      return _$blogPostListItemStatusEnum_published;
    case 'archived':
      return _$blogPostListItemStatusEnum_archived;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<BlogPostListItemStatusEnum> _$blogPostListItemStatusEnumValues =
    BuiltSet<BlogPostListItemStatusEnum>(const <BlogPostListItemStatusEnum>[
      _$blogPostListItemStatusEnum_draft,
      _$blogPostListItemStatusEnum_scheduled,
      _$blogPostListItemStatusEnum_published,
      _$blogPostListItemStatusEnum_archived,
    ]);

Serializer<BlogPostListItemStatusEnum> _$blogPostListItemStatusEnumSerializer =
    _$BlogPostListItemStatusEnumSerializer();

class _$BlogPostListItemStatusEnumSerializer
    implements PrimitiveSerializer<BlogPostListItemStatusEnum> {
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
  final Iterable<Type> types = const <Type>[BlogPostListItemStatusEnum];
  @override
  final String wireName = 'BlogPostListItemStatusEnum';

  @override
  Object serialize(
    Serializers serializers,
    BlogPostListItemStatusEnum object, {
    FullType specifiedType = FullType.unspecified,
  }) => _toWire[object.name] ?? object.name;

  @override
  BlogPostListItemStatusEnum deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) => BlogPostListItemStatusEnum.valueOf(
    _fromWire[serialized] ?? (serialized is String ? serialized : ''),
  );
}

class _$BlogPostListItem extends BlogPostListItem {
  @override
  final int id;
  @override
  final String slug;
  @override
  final BlogPostListItemStatusEnum status;
  @override
  final String title;
  @override
  final DateTime updatedAt;
  @override
  final BlogCategoryResponse? category;
  @override
  final String? coverUrl;
  @override
  final String? excerpt;
  @override
  final DateTime? publishedAt;
  @override
  final String? seoDescription;
  @override
  final String? seoTitle;
  @override
  final BuiltList<BlogTagResponse>? tags;

  factory _$BlogPostListItem([
    void Function(BlogPostListItemBuilder)? updates,
  ]) => (BlogPostListItemBuilder()..update(updates))._build();

  _$BlogPostListItem._({
    required this.id,
    required this.slug,
    required this.status,
    required this.title,
    required this.updatedAt,
    this.category,
    this.coverUrl,
    this.excerpt,
    this.publishedAt,
    this.seoDescription,
    this.seoTitle,
    this.tags,
  }) : super._();
  @override
  BlogPostListItem rebuild(void Function(BlogPostListItemBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BlogPostListItemBuilder toBuilder() =>
      BlogPostListItemBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogPostListItem &&
        id == other.id &&
        slug == other.slug &&
        status == other.status &&
        title == other.title &&
        updatedAt == other.updatedAt &&
        category == other.category &&
        coverUrl == other.coverUrl &&
        excerpt == other.excerpt &&
        publishedAt == other.publishedAt &&
        seoDescription == other.seoDescription &&
        seoTitle == other.seoTitle &&
        tags == other.tags;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jc(_$hash, updatedAt.hashCode);
    _$hash = $jc(_$hash, category.hashCode);
    _$hash = $jc(_$hash, coverUrl.hashCode);
    _$hash = $jc(_$hash, excerpt.hashCode);
    _$hash = $jc(_$hash, publishedAt.hashCode);
    _$hash = $jc(_$hash, seoDescription.hashCode);
    _$hash = $jc(_$hash, seoTitle.hashCode);
    _$hash = $jc(_$hash, tags.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogPostListItem')
          ..add('id', id)
          ..add('slug', slug)
          ..add('status', status)
          ..add('title', title)
          ..add('updatedAt', updatedAt)
          ..add('category', category)
          ..add('coverUrl', coverUrl)
          ..add('excerpt', excerpt)
          ..add('publishedAt', publishedAt)
          ..add('seoDescription', seoDescription)
          ..add('seoTitle', seoTitle)
          ..add('tags', tags))
        .toString();
  }
}

class BlogPostListItemBuilder
    implements Builder<BlogPostListItem, BlogPostListItemBuilder> {
  _$BlogPostListItem? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  BlogPostListItemStatusEnum? _status;
  BlogPostListItemStatusEnum? get status => _$this._status;
  set status(BlogPostListItemStatusEnum? status) => _$this._status = status;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  DateTime? _updatedAt;
  DateTime? get updatedAt => _$this._updatedAt;
  set updatedAt(DateTime? updatedAt) => _$this._updatedAt = updatedAt;

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

  BlogPostListItemBuilder() {
    BlogPostListItem._defaults(this);
  }

  BlogPostListItemBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _slug = $v.slug;
      _status = $v.status;
      _title = $v.title;
      _updatedAt = $v.updatedAt;
      _category = $v.category?.toBuilder();
      _coverUrl = $v.coverUrl;
      _excerpt = $v.excerpt;
      _publishedAt = $v.publishedAt;
      _seoDescription = $v.seoDescription;
      _seoTitle = $v.seoTitle;
      _tags = $v.tags?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogPostListItem other) {
    _$v = other as _$BlogPostListItem;
  }

  @override
  void update(void Function(BlogPostListItemBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogPostListItem build() => _build();

  _$BlogPostListItem _build() {
    _$BlogPostListItem _$result;
    try {
      _$result =
          _$v ??
          _$BlogPostListItem._(
            id: BuiltValueNullFieldError.checkNotNull(
              id,
              r'BlogPostListItem',
              'id',
            ),
            slug: BuiltValueNullFieldError.checkNotNull(
              slug,
              r'BlogPostListItem',
              'slug',
            ),
            status: BuiltValueNullFieldError.checkNotNull(
              status,
              r'BlogPostListItem',
              'status',
            ),
            title: BuiltValueNullFieldError.checkNotNull(
              title,
              r'BlogPostListItem',
              'title',
            ),
            updatedAt: BuiltValueNullFieldError.checkNotNull(
              updatedAt,
              r'BlogPostListItem',
              'updatedAt',
            ),
            category: _category?.build(),
            coverUrl: coverUrl,
            excerpt: excerpt,
            publishedAt: publishedAt,
            seoDescription: seoDescription,
            seoTitle: seoTitle,
            tags: _tags?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'category';
        _category?.build();

        _$failedField = 'tags';
        _tags?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
          r'BlogPostListItem',
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
