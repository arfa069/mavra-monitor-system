// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_post_update.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const BlogPostUpdateStatusEnum _$blogPostUpdateStatusEnum_draft =
    const BlogPostUpdateStatusEnum._('draft');
const BlogPostUpdateStatusEnum _$blogPostUpdateStatusEnum_scheduled =
    const BlogPostUpdateStatusEnum._('scheduled');
const BlogPostUpdateStatusEnum _$blogPostUpdateStatusEnum_published =
    const BlogPostUpdateStatusEnum._('published');
const BlogPostUpdateStatusEnum _$blogPostUpdateStatusEnum_archived =
    const BlogPostUpdateStatusEnum._('archived');

BlogPostUpdateStatusEnum _$blogPostUpdateStatusEnumValueOf(String name) {
  switch (name) {
    case 'draft':
      return _$blogPostUpdateStatusEnum_draft;
    case 'scheduled':
      return _$blogPostUpdateStatusEnum_scheduled;
    case 'published':
      return _$blogPostUpdateStatusEnum_published;
    case 'archived':
      return _$blogPostUpdateStatusEnum_archived;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<BlogPostUpdateStatusEnum> _$blogPostUpdateStatusEnumValues =
    BuiltSet<BlogPostUpdateStatusEnum>(const <BlogPostUpdateStatusEnum>[
  _$blogPostUpdateStatusEnum_draft,
  _$blogPostUpdateStatusEnum_scheduled,
  _$blogPostUpdateStatusEnum_published,
  _$blogPostUpdateStatusEnum_archived,
]);

Serializer<BlogPostUpdateStatusEnum> _$blogPostUpdateStatusEnumSerializer =
    _$BlogPostUpdateStatusEnumSerializer();

class _$BlogPostUpdateStatusEnumSerializer
    implements PrimitiveSerializer<BlogPostUpdateStatusEnum> {
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
  final Iterable<Type> types = const <Type>[BlogPostUpdateStatusEnum];
  @override
  final String wireName = 'BlogPostUpdateStatusEnum';

  @override
  Object serialize(Serializers serializers, BlogPostUpdateStatusEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  BlogPostUpdateStatusEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      BlogPostUpdateStatusEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$BlogPostUpdate extends BlogPostUpdate {
  @override
  final String? canonicalUrl;
  @override
  final int? categoryId;
  @override
  final String? categoryName;
  @override
  final String? contentHtml;
  @override
  final BuiltMap<String, JsonObject?>? contentJson;
  @override
  final int? coverMediaId;
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
  final String? slug;
  @override
  final BlogPostUpdateStatusEnum? status;
  @override
  final BuiltList<int>? tagIds;
  @override
  final BuiltList<String>? tagNames;
  @override
  final String? title;

  factory _$BlogPostUpdate([void Function(BlogPostUpdateBuilder)? updates]) =>
      (BlogPostUpdateBuilder()..update(updates))._build();

  _$BlogPostUpdate._(
      {this.canonicalUrl,
      this.categoryId,
      this.categoryName,
      this.contentHtml,
      this.contentJson,
      this.coverMediaId,
      this.coverUrl,
      this.excerpt,
      this.ogImageUrl,
      this.publishedAt,
      this.seoDescription,
      this.seoTitle,
      this.slug,
      this.status,
      this.tagIds,
      this.tagNames,
      this.title})
      : super._();
  @override
  BlogPostUpdate rebuild(void Function(BlogPostUpdateBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BlogPostUpdateBuilder toBuilder() => BlogPostUpdateBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogPostUpdate &&
        canonicalUrl == other.canonicalUrl &&
        categoryId == other.categoryId &&
        categoryName == other.categoryName &&
        contentHtml == other.contentHtml &&
        contentJson == other.contentJson &&
        coverMediaId == other.coverMediaId &&
        coverUrl == other.coverUrl &&
        excerpt == other.excerpt &&
        ogImageUrl == other.ogImageUrl &&
        publishedAt == other.publishedAt &&
        seoDescription == other.seoDescription &&
        seoTitle == other.seoTitle &&
        slug == other.slug &&
        status == other.status &&
        tagIds == other.tagIds &&
        tagNames == other.tagNames &&
        title == other.title;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, canonicalUrl.hashCode);
    _$hash = $jc(_$hash, categoryId.hashCode);
    _$hash = $jc(_$hash, categoryName.hashCode);
    _$hash = $jc(_$hash, contentHtml.hashCode);
    _$hash = $jc(_$hash, contentJson.hashCode);
    _$hash = $jc(_$hash, coverMediaId.hashCode);
    _$hash = $jc(_$hash, coverUrl.hashCode);
    _$hash = $jc(_$hash, excerpt.hashCode);
    _$hash = $jc(_$hash, ogImageUrl.hashCode);
    _$hash = $jc(_$hash, publishedAt.hashCode);
    _$hash = $jc(_$hash, seoDescription.hashCode);
    _$hash = $jc(_$hash, seoTitle.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, status.hashCode);
    _$hash = $jc(_$hash, tagIds.hashCode);
    _$hash = $jc(_$hash, tagNames.hashCode);
    _$hash = $jc(_$hash, title.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogPostUpdate')
          ..add('canonicalUrl', canonicalUrl)
          ..add('categoryId', categoryId)
          ..add('categoryName', categoryName)
          ..add('contentHtml', contentHtml)
          ..add('contentJson', contentJson)
          ..add('coverMediaId', coverMediaId)
          ..add('coverUrl', coverUrl)
          ..add('excerpt', excerpt)
          ..add('ogImageUrl', ogImageUrl)
          ..add('publishedAt', publishedAt)
          ..add('seoDescription', seoDescription)
          ..add('seoTitle', seoTitle)
          ..add('slug', slug)
          ..add('status', status)
          ..add('tagIds', tagIds)
          ..add('tagNames', tagNames)
          ..add('title', title))
        .toString();
  }
}

class BlogPostUpdateBuilder
    implements Builder<BlogPostUpdate, BlogPostUpdateBuilder> {
  _$BlogPostUpdate? _$v;

  String? _canonicalUrl;
  String? get canonicalUrl => _$this._canonicalUrl;
  set canonicalUrl(String? canonicalUrl) => _$this._canonicalUrl = canonicalUrl;

  int? _categoryId;
  int? get categoryId => _$this._categoryId;
  set categoryId(int? categoryId) => _$this._categoryId = categoryId;

  String? _categoryName;
  String? get categoryName => _$this._categoryName;
  set categoryName(String? categoryName) => _$this._categoryName = categoryName;

  String? _contentHtml;
  String? get contentHtml => _$this._contentHtml;
  set contentHtml(String? contentHtml) => _$this._contentHtml = contentHtml;

  MapBuilder<String, JsonObject?>? _contentJson;
  MapBuilder<String, JsonObject?> get contentJson =>
      _$this._contentJson ??= MapBuilder<String, JsonObject?>();
  set contentJson(MapBuilder<String, JsonObject?>? contentJson) =>
      _$this._contentJson = contentJson;

  int? _coverMediaId;
  int? get coverMediaId => _$this._coverMediaId;
  set coverMediaId(int? coverMediaId) => _$this._coverMediaId = coverMediaId;

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

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  BlogPostUpdateStatusEnum? _status;
  BlogPostUpdateStatusEnum? get status => _$this._status;
  set status(BlogPostUpdateStatusEnum? status) => _$this._status = status;

  ListBuilder<int>? _tagIds;
  ListBuilder<int> get tagIds => _$this._tagIds ??= ListBuilder<int>();
  set tagIds(ListBuilder<int>? tagIds) => _$this._tagIds = tagIds;

  ListBuilder<String>? _tagNames;
  ListBuilder<String> get tagNames =>
      _$this._tagNames ??= ListBuilder<String>();
  set tagNames(ListBuilder<String>? tagNames) => _$this._tagNames = tagNames;

  String? _title;
  String? get title => _$this._title;
  set title(String? title) => _$this._title = title;

  BlogPostUpdateBuilder() {
    BlogPostUpdate._defaults(this);
  }

  BlogPostUpdateBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _canonicalUrl = $v.canonicalUrl;
      _categoryId = $v.categoryId;
      _categoryName = $v.categoryName;
      _contentHtml = $v.contentHtml;
      _contentJson = $v.contentJson?.toBuilder();
      _coverMediaId = $v.coverMediaId;
      _coverUrl = $v.coverUrl;
      _excerpt = $v.excerpt;
      _ogImageUrl = $v.ogImageUrl;
      _publishedAt = $v.publishedAt;
      _seoDescription = $v.seoDescription;
      _seoTitle = $v.seoTitle;
      _slug = $v.slug;
      _status = $v.status;
      _tagIds = $v.tagIds?.toBuilder();
      _tagNames = $v.tagNames?.toBuilder();
      _title = $v.title;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogPostUpdate other) {
    _$v = other as _$BlogPostUpdate;
  }

  @override
  void update(void Function(BlogPostUpdateBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogPostUpdate build() => _build();

  _$BlogPostUpdate _build() {
    _$BlogPostUpdate _$result;
    try {
      _$result = _$v ??
          _$BlogPostUpdate._(
            canonicalUrl: canonicalUrl,
            categoryId: categoryId,
            categoryName: categoryName,
            contentHtml: contentHtml,
            contentJson: _contentJson?.build(),
            coverMediaId: coverMediaId,
            coverUrl: coverUrl,
            excerpt: excerpt,
            ogImageUrl: ogImageUrl,
            publishedAt: publishedAt,
            seoDescription: seoDescription,
            seoTitle: seoTitle,
            slug: slug,
            status: status,
            tagIds: _tagIds?.build(),
            tagNames: _tagNames?.build(),
            title: title,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'contentJson';
        _contentJson?.build();

        _$failedField = 'tagIds';
        _tagIds?.build();
        _$failedField = 'tagNames';
        _tagNames?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BlogPostUpdate', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
