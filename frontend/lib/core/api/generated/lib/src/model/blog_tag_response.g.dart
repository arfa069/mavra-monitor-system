// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_tag_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BlogTagResponse extends BlogTagResponse {
  @override
  final int id;
  @override
  final String name;
  @override
  final String slug;

  factory _$BlogTagResponse([void Function(BlogTagResponseBuilder)? updates]) =>
      (BlogTagResponseBuilder()..update(updates))._build();

  _$BlogTagResponse._(
      {required this.id, required this.name, required this.slug})
      : super._();
  @override
  BlogTagResponse rebuild(void Function(BlogTagResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BlogTagResponseBuilder toBuilder() => BlogTagResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogTagResponse &&
        id == other.id &&
        name == other.name &&
        slug == other.slug;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, name.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogTagResponse')
          ..add('id', id)
          ..add('name', name)
          ..add('slug', slug))
        .toString();
  }
}

class BlogTagResponseBuilder
    implements Builder<BlogTagResponse, BlogTagResponseBuilder> {
  _$BlogTagResponse? _$v;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _name;
  String? get name => _$this._name;
  set name(String? name) => _$this._name = name;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  BlogTagResponseBuilder() {
    BlogTagResponse._defaults(this);
  }

  BlogTagResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _name = $v.name;
      _slug = $v.slug;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogTagResponse other) {
    _$v = other as _$BlogTagResponse;
  }

  @override
  void update(void Function(BlogTagResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogTagResponse build() => _build();

  _$BlogTagResponse _build() {
    final _$result = _$v ??
        _$BlogTagResponse._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'BlogTagResponse', 'id'),
          name: BuiltValueNullFieldError.checkNotNull(
              name, r'BlogTagResponse', 'name'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'BlogTagResponse', 'slug'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
