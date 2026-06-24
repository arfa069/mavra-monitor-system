import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/core/theme/app_theme.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/blog/domain/blog_models.dart';
import 'package:mavra_frontend/features/blog/presentation/blog_page.dart';

void main() {
  testWidgets('renders posts, taxonomy, status, and editor entry points', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: _FakeBlogRepository.full())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Blog Studio'), findsOneWidget);
    expect(find.text('Public writing'), findsOneWidget);
    expect(find.text('Morning note'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('Ops'), findsWidgets);
    expect(find.text('pricing'), findsWidgets);
    expect(find.text('New post'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('applies search and status filters', (tester) async {
    final repository = _FakeBlogRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('blog-search-field')),
      'morning',
    );
    await tester.tap(find.byKey(const Key('blog-status-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blog-apply-filters-button')));
    await tester.pumpAndSettle();

    expect(repository.lastFilter.keyword, 'morning');
    expect(repository.lastFilter.status, 'draft');
  });

  testWidgets('matches React blog table and editor parity affordances', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: _FakeBlogRepository.full())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MavraResponsiveDataView<BlogPostItem>), findsOneWidget);
    expect(find.byType(DataTable), findsOneWidget);
    expect(find.byKey(const Key('blog-post-row-1')), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Taxonomy'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);

    await tester.tap(find.byKey(const Key('blog-new-post-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('blog-editor-dialog')), findsOneWidget);
    expect(find.byKey(const Key('blog-cover-upload-button')), findsOneWidget);
    expect(find.byKey(const Key('blog-excerpt-field')), findsOneWidget);
    expect(find.byKey(const Key('blog-editor-bold-button')), findsOneWidget);
    expect(find.byKey(const Key('blog-editor-italic-button')), findsOneWidget);
    expect(
      find.byKey(const Key('blog-editor-bullet-list-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('blog-editor-numbered-list-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('blog-editor-link-button')), findsOneWidget);
    expect(find.byKey(const Key('blog-editor-image-button')), findsOneWidget);
    expect(find.byKey(const Key('blog-canonical-url-field')), findsOneWidget);
    expect(find.byKey(const Key('blog-og-image-field')), findsOneWidget);
  });

  testWidgets('keeps header and filter buttons compact under app theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: BlogPage(repository: _FakeBlogRepository.full()),
      ),
    );
    await tester.pumpAndSettle();

    final newPostSize = tester.getSize(
      find.byKey(const Key('blog-new-post-button')),
    );
    final applyFiltersSize = tester.getSize(
      find.byKey(const Key('blog-apply-filters-button')),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('blog-apply-filters-button'))).dy,
      tester.getTopLeft(find.byKey(const Key('blog-status-filter'))).dy,
    );
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('blog-apply-filters-button')))
          .dy,
      tester.getBottomLeft(find.byKey(const Key('blog-status-filter'))).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('blog-new-post-button'))).dy,
      tester.getTopLeft(find.byKey(const Key('blog-status-filter'))).dy,
    );
    expect(
      tester.getBottomLeft(find.byKey(const Key('blog-new-post-button'))).dy,
      tester.getBottomLeft(find.byKey(const Key('blog-status-filter'))).dy,
    );
    final newPostTop = tester.getTopLeft(
      find.byKey(const Key('blog-new-post-button')),
    ).dy;
    final titleBottom = tester.getBottomLeft(find.text('Blog Studio')).dy;

    expect(newPostSize.width, lessThan(180));
    expect(applyFiltersSize.width, lessThan(190));
    expect(newPostTop, greaterThan(titleBottom));
  });

  testWidgets('creates posts and validates required editor fields', (
    tester,
  ) async {
    final repository = _FakeBlogRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('blog-new-post-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save post'));
    await tester.pumpAndSettle();

    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('Body is required'), findsOneWidget);
    expect(repository.savedDrafts, isEmpty);

    await tester.enterText(
      find.byKey(const Key('blog-title-field')),
      'Launch recap',
    );
    await tester.enterText(
      find.byKey(const Key('blog-slug-field')),
      'launch-recap',
    );
    await tester.enterText(
      find.byKey(const Key('blog-body-field')),
      'A compact markdown recap.',
    );
    await tester.enterText(find.byKey(const Key('blog-category-field')), 'Ops');
    await tester.enterText(
      find.byKey(const Key('blog-tags-field')),
      'pricing, launch',
    );
    await tester.enterText(
      find.byKey(const Key('blog-published-at-field')),
      '2026-06-18T09:30:00Z',
    );
    await tester.enterText(
      find.byKey(const Key('blog-seo-title-field')),
      'Launch recap SEO',
    );
    await tester.enterText(
      find.byKey(const Key('blog-seo-description-field')),
      'A launch recap for search previews.',
    );
    await tester.enterText(
      find.byKey(const Key('blog-canonical-url-field')),
      'https://example.com/blog/launch-recap',
    );
    await tester.enterText(
      find.byKey(const Key('blog-og-image-field')),
      '/blog-media/launch-og.png',
    );
    await tester.ensureVisible(find.text('Save post'));
    await tester.tap(find.text('Save post'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.last.title, 'Launch recap');
    expect(repository.savedDrafts.last.slug, 'launch-recap');
    expect(repository.savedDrafts.last.body, 'A compact markdown recap.');
    expect(repository.savedDrafts.last.categoryName, 'Ops');
    expect(repository.savedDrafts.last.tagNames, ['pricing', 'launch']);
    expect(
      repository.savedDrafts.last.publishedAt,
      DateTime.parse('2026-06-18T09:30:00Z'),
    );
    expect(repository.savedDrafts.last.seoTitle, 'Launch recap SEO');
    expect(
      repository.savedDrafts.last.seoDescription,
      'A launch recap for search previews.',
    );
    expect(
      repository.savedDrafts.last.canonicalUrl,
      'https://example.com/blog/launch-recap',
    );
    expect(repository.savedDrafts.last.ogImageUrl, '/blog-media/launch-og.png');
    expect(
      repository.savedDrafts.last.editor.html,
      contains('A compact markdown recap.'),
    );
    expect(repository.savedDrafts.last.editor.json['type'], 'doc');
    expect(repository.updatedPostId, isNull);
  });

  testWidgets('scheduled posts require a publish time', (tester) async {
    final repository = _FakeBlogRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('blog-new-post-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('blog-title-field')),
      'Scheduled draft',
    );
    await tester.tap(find.byKey(const Key('blog-status-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scheduled').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('blog-body-field')),
      'This needs a date.',
    );
    await tester.ensureVisible(find.text('Save post'));
    await tester.tap(find.text('Save post'));
    await tester.pumpAndSettle();

    expect(find.text('Scheduled posts need a publish time'), findsOneWidget);
    expect(repository.savedDrafts, isEmpty);
  });

  testWidgets('edits posts and saves status changes', (tester) async {
    final repository = _FakeBlogRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blog-status-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Published').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('blog-body-field')),
      'Published from Flutter.',
    );
    await tester.tap(find.text('Save post'));
    await tester.pumpAndSettle();

    expect(repository.loadedPostId, 1);
    expect(repository.updatedPostId, 1);
    expect(repository.savedDrafts.last.status, 'published');
    expect(repository.savedDrafts.last.body, 'Published from Flutter.');
  });

  testWidgets('uploads media and keeps failed editor content on screen', (
    tester,
  ) async {
    final repository = _FailingSaveBlogRepository.full();

    await tester.pumpWidget(
      MaterialApp(
        home: BlogPage(
          repository: repository,
          fileService: const _FakeFileService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('blog-new-post-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Upload media'));
    await tester.tap(find.text('Upload media'));
    await tester.pumpAndSettle();

    expect(repository.uploadedFileName, 'cover.png');
    expect(find.text('Uploaded cover.png'), findsOneWidget);
    expect(find.text('/blog-media/cover.png'), findsWidgets);

    await tester.enterText(
      find.byKey(const Key('blog-title-field')),
      'Persistent draft',
    );
    await tester.enterText(
      find.byKey(const Key('blog-body-field')),
      'Still here after failure.',
    );
    await tester.ensureVisible(find.text('Save post'));
    await tester.tap(find.text('Save post'));
    await tester.pumpAndSettle();

    final bodyField = tester.widget<TextField>(
      find.byKey(const Key('blog-body-field')),
    );
    expect(find.text('Blog post save failed.'), findsOneWidget);
    expect(bodyField.controller?.text, 'Still here after failure.');
  });

  testWidgets('renders loading, empty, error, and permission denied states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: _SlowBlogRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载 Blog Studio...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: _FakeBlogRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('还没有文章草稿。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: BlogPage(repository: _FailingLoadBlogRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Blog Studio 加载失败。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: BlogPage(
          repository: _FakeBlogRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有权限访问 Blog Studio。'), findsOneWidget);
  });
}

class _FakeBlogRepository implements BlogRepository {
  _FakeBlogRepository(this.snapshot);

  factory _FakeBlogRepository.full() => _FakeBlogRepository(
    BlogSnapshot(
      posts: [
        BlogPostItem(
          id: 1,
          title: 'Morning note',
          slug: 'morning-note',
          status: 'draft',
          excerpt: 'Brief operating note.',
          updatedAt: DateTime.utc(2026, 6, 16, 8),
          categoryName: 'Ops',
          tagNames: const ['pricing'],
          coverUrl: null,
        ),
      ],
      categories: const [BlogCategory(id: 1, name: 'Ops', slug: 'ops')],
      tags: const [BlogTag(id: 1, name: 'pricing', slug: 'pricing')],
      totalPosts: 1,
    ),
  );

  factory _FakeBlogRepository.empty() => _FakeBlogRepository(
    const BlogSnapshot(posts: [], categories: [], tags: [], totalPosts: 0),
  );

  final BlogSnapshot snapshot;
  final savedDrafts = <BlogPostDraft>[];
  BlogFilter lastFilter = const BlogFilter();
  int? loadedPostId;
  int? updatedPostId;
  String? uploadedFileName;

  @override
  Future<BlogSnapshot> loadBlog(BlogFilter filter) async {
    lastFilter = filter;
    return snapshot;
  }

  @override
  Future<BlogSnapshot> listPosts(BlogFilter filter) => loadBlog(filter);

  @override
  Future<List<BlogCategory>> listCategories() async => snapshot.categories;

  @override
  Future<List<BlogTag>> listTags() async => snapshot.tags;

  @override
  Future<BlogPostDraft> loadPostDraft(int postId) async {
    loadedPostId = postId;
    return BlogPostDraft(
      title: 'Morning note',
      slug: 'morning-note',
      status: 'draft',
      body: 'Existing markdown body.',
      editor: BlogEditorValue.fromBody('Existing markdown body.'),
      excerpt: 'Brief operating note.',
      categoryName: 'Ops',
      tagNames: ['pricing'],
      coverUrl: null,
      publishedAt: DateTime.utc(2026, 6, 18, 9),
      seoTitle: 'Morning note SEO',
      seoDescription: 'Morning note description.',
      canonicalUrl: 'https://example.com/blog/morning-note',
      ogImageUrl: '/blog-media/morning-og.png',
    );
  }

  @override
  Future<void> savePost(BlogPostDraft draft, {int? postId}) async {
    savedDrafts.add(draft);
    updatedPostId = postId;
  }

  @override
  Future<BlogMediaAsset> uploadMedia(PickedFileReference file) async {
    uploadedFileName = file.name;
    return const BlogMediaAsset(
      id: 7,
      fileName: 'cover.png',
      publicUrl: '/blog-media/cover.png',
    );
  }
}

class _SlowBlogRepository implements BlogRepository {
  final _completer = Completer<BlogSnapshot>();

  @override
  Future<BlogSnapshot> loadBlog(BlogFilter filter) => _completer.future;

  @override
  Future<BlogSnapshot> listPosts(BlogFilter filter) => loadBlog(filter);

  @override
  Future<List<BlogCategory>> listCategories() async => const [];

  @override
  Future<List<BlogTag>> listTags() async => const [];

  @override
  Future<BlogPostDraft> loadPostDraft(int postId) async =>
      throw UnimplementedError();

  @override
  Future<void> savePost(BlogPostDraft draft, {int? postId}) async {}

  @override
  Future<BlogMediaAsset> uploadMedia(PickedFileReference file) async =>
      throw UnimplementedError();
}

class _FailingLoadBlogRepository implements BlogRepository {
  @override
  Future<BlogSnapshot> loadBlog(BlogFilter filter) {
    throw StateError('blog down');
  }

  @override
  Future<BlogSnapshot> listPosts(BlogFilter filter) => loadBlog(filter);

  @override
  Future<List<BlogCategory>> listCategories() async => const [];

  @override
  Future<List<BlogTag>> listTags() async => const [];

  @override
  Future<BlogPostDraft> loadPostDraft(int postId) async =>
      throw UnimplementedError();

  @override
  Future<void> savePost(BlogPostDraft draft, {int? postId}) async {}

  @override
  Future<BlogMediaAsset> uploadMedia(PickedFileReference file) async =>
      throw UnimplementedError();
}

class _FailingSaveBlogRepository extends _FakeBlogRepository {
  _FailingSaveBlogRepository(super.snapshot);

  factory _FailingSaveBlogRepository.full() =>
      _FailingSaveBlogRepository(_FakeBlogRepository.full().snapshot);

  @override
  Future<void> savePost(BlogPostDraft draft, {int? postId}) {
    throw StateError('save down');
  }
}

class _FakeFileService extends FileService {
  const _FakeFileService()
    : super(canPickFiles: true, canSaveFiles: false, canDownloadFiles: false);

  @override
  Future<PickedFileReference?> pickFile() async {
    return const PickedFileReference(name: 'cover.png', bytes: [1, 2, 3]);
  }
}
