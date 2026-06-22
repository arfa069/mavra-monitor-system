import '../../../core/files/file_service.dart';

class BlogPostItem {
  const BlogPostItem({
    required this.id,
    required this.title,
    required this.slug,
    required this.status,
    required this.excerpt,
    required this.updatedAt,
    required this.categoryName,
    required this.tagNames,
    required this.coverUrl,
    this.publishedAt,
    this.seoTitle,
    this.seoDescription,
  });

  final int id;
  final String title;
  final String slug;
  final String status;
  final String? excerpt;
  final DateTime updatedAt;
  final String? categoryName;
  final List<String> tagNames;
  final String? coverUrl;
  final DateTime? publishedAt;
  final String? seoTitle;
  final String? seoDescription;
}

class BlogCategory {
  const BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;
}

class BlogTag {
  const BlogTag({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;
}

class BlogMediaAsset {
  const BlogMediaAsset({
    required this.id,
    required this.fileName,
    required this.publicUrl,
  });

  final int id;
  final String fileName;
  final String publicUrl;
}

class BlogPostDraft {
  const BlogPostDraft({
    required this.title,
    required this.slug,
    required this.status,
    required this.body,
    required this.editor,
    required this.excerpt,
    required this.categoryName,
    required this.tagNames,
    required this.coverUrl,
    this.publishedAt,
    this.seoTitle,
    this.seoDescription,
    this.canonicalUrl,
    this.ogImageUrl,
  });

  const BlogPostDraft.empty()
    : title = '',
      slug = '',
      status = 'draft',
      body = '',
      editor = const BlogEditorValue.empty(),
      excerpt = null,
      categoryName = null,
      tagNames = const [],
      coverUrl = null,
      publishedAt = null,
      seoTitle = null,
      seoDescription = null,
      canonicalUrl = null,
      ogImageUrl = null;

  final String title;
  final String slug;
  final String status;
  final String body;
  final BlogEditorValue editor;
  final String? excerpt;
  final String? categoryName;
  final List<String> tagNames;
  final String? coverUrl;
  final DateTime? publishedAt;
  final String? seoTitle;
  final String? seoDescription;
  final String? canonicalUrl;
  final String? ogImageUrl;
}

class BlogEditorValue {
  const BlogEditorValue({required this.html, required this.json});

  const BlogEditorValue.empty()
    : html = '<p></p>',
      json = const <String, Object?>{
        'type': 'doc',
        'content': [
          <String, Object?>{'type': 'paragraph'},
        ],
      };

  factory BlogEditorValue.fromBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return const BlogEditorValue.empty();
    }
    final html = _looksLikeHtml(trimmed) ? body : _paragraphHtml(body);
    return BlogEditorValue(html: html, json: _docJson(body));
  }

  final String html;
  final Map<String, Object?> json;
}

bool _looksLikeHtml(String value) => RegExp(r'<[a-zA-Z][^>]*>').hasMatch(value);

String _paragraphHtml(String value) {
  final paragraphs = value
      .split(RegExp(r'\n\s*\n'))
      .map((paragraph) => paragraph.trim())
      .where((paragraph) => paragraph.isNotEmpty)
      .toList();
  if (paragraphs.isEmpty) {
    return '<p></p>';
  }
  return paragraphs
      .map(
        (paragraph) =>
            '<p>${_escapeHtml(paragraph).replaceAll('\n', '<br>')}</p>',
      )
      .join();
}

Map<String, Object?> _docJson(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return const <String, Object?>{
      'type': 'doc',
      'content': [
        <String, Object?>{'type': 'paragraph'},
      ],
    };
  }
  return <String, Object?>{
    'type': 'doc',
    'content': [
      <String, Object?>{
        'type': 'paragraph',
        'content': [
          <String, Object?>{'type': 'text', 'text': text},
        ],
      },
    ],
  };
}

String _escapeHtml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

class BlogSnapshot {
  const BlogSnapshot({
    required this.posts,
    required this.categories,
    required this.tags,
    required this.totalPosts,
  });

  const BlogSnapshot.empty()
    : posts = const [],
      categories = const [],
      tags = const [],
      totalPosts = 0;

  final List<BlogPostItem> posts;
  final List<BlogCategory> categories;
  final List<BlogTag> tags;
  final int totalPosts;

  bool get isEmpty => posts.isEmpty;
}

class BlogFilter {
  const BlogFilter({
    this.keyword,
    this.status,
    this.page = 1,
    this.pageSize = 20,
  });

  final String? keyword;
  final String? status;
  final int page;
  final int pageSize;
}

abstract class BlogRepository {
  Future<BlogSnapshot> loadBlog(BlogFilter filter);

  Future<BlogSnapshot> listPosts(BlogFilter filter);

  Future<BlogPostDraft> loadPostDraft(int postId);

  Future<void> savePost(BlogPostDraft draft, {int? postId});

  Future<BlogMediaAsset> uploadMedia(PickedFileReference file);

  Future<List<BlogCategory>> listCategories();

  Future<List<BlogTag>> listTags();
}
