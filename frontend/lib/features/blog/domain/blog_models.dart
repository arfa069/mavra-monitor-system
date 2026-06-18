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
    required this.excerpt,
    required this.categoryName,
    required this.tagNames,
    required this.coverUrl,
    this.publishedAt,
    this.seoTitle,
    this.seoDescription,
  });

  const BlogPostDraft.empty()
    : title = '',
      slug = '',
      status = 'draft',
      body = '',
      excerpt = null,
      categoryName = null,
      tagNames = const [],
      coverUrl = null,
      publishedAt = null,
      seoTitle = null,
      seoDescription = null;

  final String title;
  final String slug;
  final String status;
  final String body;
  final String? excerpt;
  final String? categoryName;
  final List<String> tagNames;
  final String? coverUrl;
  final DateTime? publishedAt;
  final String? seoTitle;
  final String? seoDescription;
}

class BlogEditorValue {
  const BlogEditorValue({required this.html, required this.json});

  final String html;
  final Map<String, Object?> json;
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
