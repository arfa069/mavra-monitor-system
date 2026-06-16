// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_category_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BlogCategoryResponse extends BlogCategoryResponse {
  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;
  @override
  final String? description;

  factory _$BlogCategoryResponse([
    void Function(BlogCategoryResponseBuilder)? updates,
  ]) => (BlogCategoryResponseBuilder()..update(updates))._build();

  _$BlogCategoryResponse._({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  }) : super._();
  @override
  BlogCategoryResponse rebuild(
    void Function(BlogCategoryResponseBuilder) updates,
  ) => (toBuilder()..update(updates)).build();

  @override
  BlogCategoryResponseBuilder toBuilder() =>
      BlogCategoryResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogCategoryResponse &&
        id == other.id &&
        name == other.name &&
        slug == other.slug &&
        description == other.description;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, description.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogCategoryResponse')
          ..add('id', id)
          ..add('name', name)
          ..add('slug', slug)
          ..add('description', description))
        .toString();
  }
}

class BlogCategoryResponseBuilder
    implements Builder<BlogCategoryResponse, BlogCategoryResponseBuilder> {
  _$BlogCategoryResponse? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _description;
  String? get description => _$this._description;
  set description(String? description) => _$this._description = description;

  BlogCategoryResponseBuilder() {
    BlogCategoryResponse._defaults(this);
  }

  BlogCategoryResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _slug = $v.slug;
      _description = $v.description;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogCategoryResponse other) {
    _$v = other as _$BlogCategoryResponse;
  }

  @override
  void update(void Function(BlogCategoryResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogCategoryResponse build() => _build();

  _$BlogCategoryResponse _build() {
    final _$result =
        _$v ??
        _$BlogCategoryResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'BlogCategoryResponse',
            'id',
          ),
          name: BuiltValueNullFieldError.checkNotNull(
            name,
            r'BlogCategoryResponse',
            'name',
          ),
          slug: BuiltValueNullFieldError.checkNotNull(
            slug,
            r'BlogCategoryResponse',
            'slug',
          ),
          description: description,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
