import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:mavra_api/mavra_api.dart' as generated;

import '../../../core/config/app_config.dart';
import '../../../core/files/file_service.dart';
import '../domain/blog_models.dart';

class GeneratedBlogRepository implements BlogRepository {
  GeneratedBlogRepository({
    required AppConfig config,
    generated.MavraApi? client,
  }) : _client =
           client ??
           generated.MavraApi(
             basePathOverride: _serviceRoot(config.apiBaseUrl),
           );

  final generated.MavraApi _client;

  generated.BlogApi get _blogApi => _client.getBlogApi();

  @override
  Future<BlogSnapshot> loadBlog(BlogFilter filter) async {
    final responses = await Future.wait([
      _blogApi.blogListAdminPosts(
        keyword: filter.keyword,
        status: filter.status,
        size: 50,
      ),
      _blogApi.blogListCategories(),
      _blogApi.blogListTags(),
    ]);

    final posts = responses[0].data as generated.BlogPostListResponse?;
    final categories =
        responses[1].data as BuiltList<generated.BlogCategoryResponse>?;
    final tags = responses[2].data as BuiltList<generated.BlogTagResponse>?;

    return BlogSnapshot(
      posts: [
        for (final post in posts?.items.toList() ?? const [])
          BlogPostItem(
            id: post.id,
            title: post.title,
            slug: post.slug,
            status: post.status.name,
            excerpt: post.excerpt,
            updatedAt: post.updatedAt,
            categoryName: post.category?.name,
            tagNames: [
              for (final tag in post.tags?.toList() ?? const []) tag.name,
            ],
            coverUrl: post.coverUrl,
            publishedAt: post.publishedAt,
            seoTitle: post.seoTitle,
            seoDescription: post.seoDescription,
          ),
      ],
      categories: [
        for (final category in categories?.toList() ?? const [])
          BlogCategory(
            id: category.id,
            name: category.name,
            slug: category.slug,
          ),
      ],
      tags: [
        for (final tag in tags?.toList() ?? const [])
          BlogTag(id: tag.id, name: tag.name, slug: tag.slug),
      ],
      totalPosts: posts?.total ?? 0,
    );
  }

  @override
  Future<BlogPostDraft> loadPostDraft(int postId) async {
    final response = await _blogApi.blogGetAdminPost(postId: postId);
    final post = response.data;
    if (post == null) {
      throw StateError('Blog post #$postId was not returned by the API.');
    }
    return BlogPostDraft(
      title: post.title,
      slug: post.slug,
      status: post.status.name,
      body: post.contentText,
      excerpt: post.excerpt,
      categoryName: post.category?.name,
      tagNames: [for (final tag in post.tags?.toList() ?? const []) tag.name],
      coverUrl: post.coverUrl,
      publishedAt: post.publishedAt,
      seoTitle: post.seoTitle,
      seoDescription: post.seoDescription,
    );
  }

  @override
  Future<void> savePost(BlogPostDraft draft, {int? postId}) async {
    if (postId == null) {
      await _blogApi.blogCreateAdminPost(
        blogPostCreate: generated.BlogPostCreate(
          (builder) => builder
            ..title = draft.title
            ..slug = _blankToNull(draft.slug)
            ..status = _createStatus(draft.status)
            ..contentHtml = draft.body
            ..excerpt = _blankToNull(draft.excerpt)
            ..categoryName = _blankToNull(draft.categoryName)
            ..coverUrl = _blankToNull(draft.coverUrl)
            ..publishedAt = draft.publishedAt
            ..seoTitle = _blankToNull(draft.seoTitle)
            ..seoDescription = _blankToNull(draft.seoDescription)
            ..tagNames.replace(draft.tagNames),
        ),
      );
      return;
    }

    await _blogApi.blogUpdateAdminPost(
      postId: postId,
      blogPostUpdate: generated.BlogPostUpdate(
        (builder) => builder
          ..title = draft.title
          ..slug = _blankToNull(draft.slug)
          ..status = _updateStatus(draft.status)
          ..contentHtml = draft.body
          ..excerpt = _blankToNull(draft.excerpt)
          ..categoryName = _blankToNull(draft.categoryName)
          ..coverUrl = _blankToNull(draft.coverUrl)
          ..publishedAt = draft.publishedAt
          ..seoTitle = _blankToNull(draft.seoTitle)
          ..seoDescription = _blankToNull(draft.seoDescription)
          ..tagNames.replace(draft.tagNames),
      ),
    );
  }

  @override
  Future<BlogMediaAsset> uploadMedia(PickedFileReference file) async {
    final bytes = file.bytes;
    if (bytes == null) {
      throw UnsupportedError('Blog media upload requires readable file bytes.');
    }
    final response = await _blogApi.blogUploadBlogMedia(
      file: MultipartFile.fromBytes(bytes, filename: file.name),
    );
    final media = response.data;
    if (media == null) {
      throw StateError('Blog media upload did not return an asset.');
    }
    return BlogMediaAsset(
      id: media.id,
      fileName: media.originalName,
      publicUrl: media.publicUrl,
    );
  }

  static generated.BlogPostCreateStatusEnum _createStatus(String status) {
    switch (status) {
      case 'scheduled':
        return generated.BlogPostCreateStatusEnum.scheduled;
      case 'published':
        return generated.BlogPostCreateStatusEnum.published;
      case 'archived':
        return generated.BlogPostCreateStatusEnum.archived;
      case 'draft':
      default:
        return generated.BlogPostCreateStatusEnum.draft;
    }
  }

  static generated.BlogPostUpdateStatusEnum _updateStatus(String status) {
    switch (status) {
      case 'scheduled':
        return generated.BlogPostUpdateStatusEnum.scheduled;
      case 'published':
        return generated.BlogPostUpdateStatusEnum.published;
      case 'archived':
        return generated.BlogPostUpdateStatusEnum.archived;
      case 'draft':
      default:
        return generated.BlogPostUpdateStatusEnum.draft;
    }
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static String _serviceRoot(String apiBaseUrl) {
    const apiPrefix = '/api/v1';
    if (apiBaseUrl.endsWith(apiPrefix)) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - apiPrefix.length);
    }
    return apiBaseUrl;
  }
}
