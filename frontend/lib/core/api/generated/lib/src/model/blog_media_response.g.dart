// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'blog_media_response.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BlogMediaResponse extends BlogMediaResponse {
  @override
  final String contentType;
  @override
  final DateTime createdAt;
  @override
  final String fileName;
  @override
  final int id;
  @override
  final String originalName;
  @override
  final String publicUrl;
  @override
  final int sizeBytes;

  factory _$BlogMediaResponse([
    void Function(BlogMediaResponseBuilder)? updates,
  ]) => (BlogMediaResponseBuilder()..update(updates))._build();

  _$BlogMediaResponse._({
    required this.contentType,
    required this.createdAt,
    required this.fileName,
    required this.id,
    required this.originalName,
    required this.publicUrl,
    required this.sizeBytes,
  }) : super._();
  @override
  BlogMediaResponse rebuild(void Function(BlogMediaResponseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BlogMediaResponseBuilder toBuilder() =>
      BlogMediaResponseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BlogMediaResponse &&
        contentType == other.contentType &&
        createdAt == other.createdAt &&
        fileName == other.fileName &&
        id == other.id &&
        originalName == other.originalName &&
        publicUrl == other.publicUrl &&
        sizeBytes == other.sizeBytes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contentType.hashCode);
    _$hash = $jc(_$hash, createdAt.hashCode);
    _$hash = $jc(_$hash, fileName.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, originalName.hashCode);
    _$hash = $jc(_$hash, publicUrl.hashCode);
    _$hash = $jc(_$hash, sizeBytes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BlogMediaResponse')
          ..add('contentType', contentType)
          ..add('createdAt', createdAt)
          ..add('fileName', fileName)
          ..add('id', id)
          ..add('originalName', originalName)
          ..add('publicUrl', publicUrl)
          ..add('sizeBytes', sizeBytes))
        .toString();
  }
}

class BlogMediaResponseBuilder
    implements Builder<BlogMediaResponse, BlogMediaResponseBuilder> {
  _$BlogMediaResponse? _$v;

  String? _contentType;
  String? get contentType => _$this._contentType;
  set contentType(String? contentType) => _$this._contentType = contentType;

  DateTime? _createdAt;
  DateTime? get createdAt => _$this._createdAt;
  set createdAt(DateTime? createdAt) => _$this._createdAt = createdAt;

  String? _fileName;
  String? get fileName => _$this._fileName;
  set fileName(String? fileName) => _$this._fileName = fileName;

  int? _id;
  int? get id => _$this._id;
  set id(int? id) => _$this._id = id;

  String? _originalName;
  String? get originalName => _$this._originalName;
  set originalName(String? originalName) => _$this._originalName = originalName;

  String? _publicUrl;
  String? get publicUrl => _$this._publicUrl;
  set publicUrl(String? publicUrl) => _$this._publicUrl = publicUrl;

  int? _sizeBytes;
  int? get sizeBytes => _$this._sizeBytes;
  set sizeBytes(int? sizeBytes) => _$this._sizeBytes = sizeBytes;

  BlogMediaResponseBuilder() {
    BlogMediaResponse._defaults(this);
  }

  BlogMediaResponseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contentType = $v.contentType;
      _createdAt = $v.createdAt;
      _fileName = $v.fileName;
      _id = $v.id;
      _originalName = $v.originalName;
      _publicUrl = $v.publicUrl;
      _sizeBytes = $v.sizeBytes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BlogMediaResponse other) {
    _$v = other as _$BlogMediaResponse;
  }

  @override
  void update(void Function(BlogMediaResponseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BlogMediaResponse build() => _build();

  _$BlogMediaResponse _build() {
    final _$result =
        _$v ??
        _$BlogMediaResponse._(
          contentType: BuiltValueNullFieldError.checkNotNull(
            contentType,
            r'BlogMediaResponse',
            'contentType',
          ),
          createdAt: BuiltValueNullFieldError.checkNotNull(
            createdAt,
            r'BlogMediaResponse',
            'createdAt',
          ),
          fileName: BuiltValueNullFieldError.checkNotNull(
            fileName,
            r'BlogMediaResponse',
            'fileName',
          ),
          id: BuiltValueNullFieldError.checkNotNull(
            id,
            r'BlogMediaResponse',
            'id',
          ),
          originalName: BuiltValueNullFieldError.checkNotNull(
            originalName,
            r'BlogMediaResponse',
            'originalName',
          ),
          publicUrl: BuiltValueNullFieldError.checkNotNull(
            publicUrl,
            r'BlogMediaResponse',
            'publicUrl',
          ),
          sizeBytes: BuiltValueNullFieldError.checkNotNull(
            sizeBytes,
            r'BlogMediaResponse',
            'sizeBytes',
          ),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
