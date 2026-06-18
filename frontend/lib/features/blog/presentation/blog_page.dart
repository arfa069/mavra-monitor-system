import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_service.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../domain/blog_models.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({
    super.key,
    required this.repository,
    this.fileService,
    this.permissions = const {'blog:read_admin', 'blog:write'},
  });

  final BlogRepository repository;
  final FileService? fileService;
  final Set<String> permissions;

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  Future<BlogSnapshot>? _blogFuture;
  BlogSnapshot? _snapshot;
  Object? _error;
  String? _statusMessage;
  int? _editingPostId;
  bool _showEditor = false;
  String _status = 'draft';
  String? _titleError;
  String? _bodyError;

  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _excerptController = TextEditingController();
  final _bodyController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagsController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _publishedAtController = TextEditingController();
  final _seoTitleController = TextEditingController();
  final _seoDescriptionController = TextEditingController();
  final _filterKeywordController = TextEditingController();
  final _filterStatusController = TextEditingController();

  FileService get _fileService =>
      widget.fileService ??
      FileService.forCapabilities(PlatformCapabilities.current());

  bool get _canRead => widget.permissions.contains('blog:read_admin');

  bool get _canWrite => widget.permissions.contains('blog:write');

  @override
  void initState() {
    super.initState();
    if (_canRead) {
      _load();
    }
  }

  @override
  void didUpdateWidget(covariant BlogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository ||
        oldWidget.permissions != widget.permissions) {
      _snapshot = null;
      if (_canRead) {
        _load();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _excerptController.dispose();
    _bodyController.dispose();
    _categoryController.dispose();
    _tagsController.dispose();
    _coverUrlController.dispose();
    _publishedAtController.dispose();
    _seoTitleController.dispose();
    _seoDescriptionController.dispose();
    _filterKeywordController.dispose();
    _filterStatusController.dispose();
    super.dispose();
  }

  void _load() {
    final filter = BlogFilter(
      keyword: _blankToNull(_filterKeywordController.text),
      status: _blankToNull(_filterStatusController.text),
    );
    setState(() {
      _error = null;
      _blogFuture = Future.sync(() => widget.repository.loadBlog(filter))
        ..then((snapshot) {
          if (mounted) {
            setState(() => _snapshot = snapshot);
          }
        }).catchError((Object error) {
          if (mounted) {
            setState(() => _error = error);
          }
        });
    });
  }

  void _newPost() {
    setState(() {
      _editingPostId = null;
      _showEditor = true;
      _status = 'draft';
      _statusMessage = null;
      _titleError = null;
      _bodyError = null;
      _titleController.clear();
      _slugController.clear();
      _excerptController.clear();
      _bodyController.clear();
      _categoryController.clear();
      _tagsController.clear();
      _coverUrlController.clear();
      _publishedAtController.clear();
      _seoTitleController.clear();
      _seoDescriptionController.clear();
    });
  }

  Future<void> _editPost(BlogPostItem post) async {
    setState(() {
      _statusMessage = 'Loading ${post.title}...';
      _titleError = null;
      _bodyError = null;
    });
    try {
      final draft = await widget.repository.loadPostDraft(post.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _editingPostId = post.id;
        _showEditor = true;
        _status = _knownStatus(draft.status);
        _statusMessage = null;
        _titleController.text = draft.title;
        _slugController.text = draft.slug;
        _excerptController.text = draft.excerpt ?? '';
        _bodyController.text = draft.body;
        _categoryController.text = draft.categoryName ?? '';
        _tagsController.text = draft.tagNames.join(', ');
        _coverUrlController.text = draft.coverUrl ?? '';
        _publishedAtController.text =
            draft.publishedAt?.toIso8601String() ?? '';
        _seoTitleController.text = draft.seoTitle ?? '';
        _seoDescriptionController.text = draft.seoDescription ?? '';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Blog post load failed.');
      }
    }
  }

  Future<void> _savePost() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    setState(() {
      _titleError = title.isEmpty ? 'Title is required' : null;
      _bodyError = body.isEmpty ? 'Body is required' : null;
      _statusMessage = null;
    });
    if (title.isEmpty || body.isEmpty) {
      return;
    }

    final draft = BlogPostDraft(
      title: title,
      slug: _slugController.text.trim(),
      status: _status,
      body: _bodyController.text,
      excerpt: _blankToNull(_excerptController.text),
      categoryName: _blankToNull(_categoryController.text),
      tagNames: _splitTags(_tagsController.text),
      coverUrl: _blankToNull(_coverUrlController.text),
      publishedAt: DateTime.tryParse(_publishedAtController.text.trim()),
      seoTitle: _blankToNull(_seoTitleController.text),
      seoDescription: _blankToNull(_seoDescriptionController.text),
    );

    try {
      await widget.repository.savePost(draft, postId: _editingPostId);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Saved ${draft.title}';
        _showEditor = false;
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Blog post save failed.');
      }
    }
  }

  Future<void> _uploadMedia() async {
    if (!_fileService.canPickFiles) {
      setState(() => _statusMessage = 'Media picking is unavailable.');
      return;
    }
    try {
      final file = await _fileService.pickFile();
      if (file == null) {
        return;
      }
      final media = await widget.repository.uploadMedia(file);
      if (!mounted) {
        return;
      }
      setState(() {
        _coverUrlController.text = media.publicUrl;
        _statusMessage = 'Uploaded ${media.fileName}';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Media upload failed.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRead) {
      return const _BlogPermissionDenied();
    }

    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.article, label: 'Blog'),
          AdaptiveDestination(icon: Icons.people, label: 'Admin'),
          AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/admin/users');
            case 3:
              context.go('/settings');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<BlogSnapshot>(
              future: _blogFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('Blog Studio 加载失败。'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('正在加载 Blog Studio...'),
                      ],
                    ),
                  );
                }
                return _BlogContent(
                  snapshot: _snapshot ?? const BlogSnapshot.empty(),
                  canWrite: _canWrite,
                  showEditor: _showEditor,
                  status: _status,
                  statusMessage: _statusMessage,
                  titleController: _titleController,
                  slugController: _slugController,
                  excerptController: _excerptController,
                  bodyController: _bodyController,
                  categoryController: _categoryController,
                  tagsController: _tagsController,
                  coverUrlController: _coverUrlController,
                  publishedAtController: _publishedAtController,
                  seoTitleController: _seoTitleController,
                  seoDescriptionController: _seoDescriptionController,
                  filterKeywordController: _filterKeywordController,
                  filterStatusController: _filterStatusController,
                  titleError: _titleError,
                  bodyError: _bodyError,
                  onNewPost: _newPost,
                  onEditPost: _editPost,
                  onSavePost: _savePost,
                  onUploadMedia: _uploadMedia,
                  onApplyFilters: _load,
                  onStatusChanged: (value) {
                    if (value != null) {
                      setState(() => _status = value);
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static String _knownStatus(String value) {
    return _blogStatuses.contains(value) ? value : 'draft';
  }

  static List<String> _splitTags(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

const _blogStatuses = ['draft', 'scheduled', 'published', 'archived'];

class _BlogPermissionDenied extends StatelessWidget {
  const _BlogPermissionDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blog Studio')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 44),
              const SizedBox(height: 16),
              const Text('没有权限访问 Blog Studio。'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => context.go('/today'),
                icon: const Icon(Icons.today),
                label: const Text('回到 Today'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BlogContent extends StatelessWidget {
  const _BlogContent({
    required this.snapshot,
    required this.canWrite,
    required this.showEditor,
    required this.status,
    required this.statusMessage,
    required this.titleController,
    required this.slugController,
    required this.excerptController,
    required this.bodyController,
    required this.categoryController,
    required this.tagsController,
    required this.coverUrlController,
    required this.publishedAtController,
    required this.seoTitleController,
    required this.seoDescriptionController,
    required this.filterKeywordController,
    required this.filterStatusController,
    required this.titleError,
    required this.bodyError,
    required this.onNewPost,
    required this.onEditPost,
    required this.onSavePost,
    required this.onUploadMedia,
    required this.onApplyFilters,
    required this.onStatusChanged,
  });

  final BlogSnapshot snapshot;
  final bool canWrite;
  final bool showEditor;
  final String status;
  final String? statusMessage;
  final TextEditingController titleController;
  final TextEditingController slugController;
  final TextEditingController excerptController;
  final TextEditingController bodyController;
  final TextEditingController categoryController;
  final TextEditingController tagsController;
  final TextEditingController coverUrlController;
  final TextEditingController publishedAtController;
  final TextEditingController seoTitleController;
  final TextEditingController seoDescriptionController;
  final TextEditingController filterKeywordController;
  final TextEditingController filterStatusController;
  final String? titleError;
  final String? bodyError;
  final VoidCallback onNewPost;
  final ValueChanged<BlogPostItem> onEditPost;
  final Future<void> Function() onSavePost;
  final Future<void> Function() onUploadMedia;
  final VoidCallback onApplyFilters;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Blog Studio',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (canWrite)
                FilledButton.icon(
                  onPressed: onNewPost,
                  icon: const Icon(Icons.add),
                  label: const Text('New post'),
                ),
            ],
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          const SizedBox(height: 12),
          _BlogFilters(
            keywordController: filterKeywordController,
            statusController: filterStatusController,
            onApplyFilters: onApplyFilters,
          ),
          const SizedBox(height: 12),
          _TaxonomyStrip(categories: snapshot.categories, tags: snapshot.tags),
          if (showEditor) ...[
            const SizedBox(height: 16),
            _BlogEditor(
              canWrite: canWrite,
              status: status,
              titleController: titleController,
              slugController: slugController,
              excerptController: excerptController,
              bodyController: bodyController,
              categoryController: categoryController,
              tagsController: tagsController,
              coverUrlController: coverUrlController,
              publishedAtController: publishedAtController,
              seoTitleController: seoTitleController,
              seoDescriptionController: seoDescriptionController,
              titleError: titleError,
              bodyError: bodyError,
              onSavePost: onSavePost,
              onUploadMedia: onUploadMedia,
              onStatusChanged: onStatusChanged,
            ),
          ],
          const SizedBox(height: 16),
          if (snapshot.isEmpty)
            const Text('还没有文章草稿。')
          else
            _PostsTable(
              posts: snapshot.posts,
              canWrite: canWrite,
              onEditPost: onEditPost,
            ),
        ],
      ),
    );
  }
}

class _TaxonomyStrip extends StatelessWidget {
  const _TaxonomyStrip({required this.categories, required this.tags});

  final List<BlogCategory> categories;
  final List<BlogTag> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Categories', style: Theme.of(context).textTheme.titleSmall),
        if (categories.isEmpty)
          const Text('No categories')
        else
          for (final category in categories) Chip(label: Text(category.name)),
        const SizedBox(width: 8),
        Text('Tags', style: Theme.of(context).textTheme.titleSmall),
        if (tags.isEmpty)
          const Text('No tags')
        else
          for (final tag in tags) Chip(label: Text(tag.name)),
      ],
    );
  }
}

class _BlogFilters extends StatelessWidget {
  const _BlogFilters({
    required this.keywordController,
    required this.statusController,
    required this.onApplyFilters,
  });

  final TextEditingController keywordController;
  final TextEditingController statusController;
  final VoidCallback onApplyFilters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 220,
          child: TextField(
            key: const Key('blog-filter-keyword-field'),
            controller: keywordController,
            decoration: const InputDecoration(labelText: 'Search posts'),
          ),
        ),
        SizedBox(
          width: 160,
          child: TextField(
            key: const Key('blog-filter-status-field'),
            controller: statusController,
            decoration: const InputDecoration(labelText: 'Status'),
          ),
        ),
        FilledButton.icon(
          key: const Key('blog-apply-filters-button'),
          onPressed: onApplyFilters,
          icon: const Icon(Icons.filter_alt),
          label: const Text('Apply filters'),
        ),
      ],
    );
  }
}

class _BlogEditor extends StatelessWidget {
  const _BlogEditor({
    required this.canWrite,
    required this.status,
    required this.titleController,
    required this.slugController,
    required this.excerptController,
    required this.bodyController,
    required this.categoryController,
    required this.tagsController,
    required this.coverUrlController,
    required this.publishedAtController,
    required this.seoTitleController,
    required this.seoDescriptionController,
    required this.titleError,
    required this.bodyError,
    required this.onSavePost,
    required this.onUploadMedia,
    required this.onStatusChanged,
  });

  final bool canWrite;
  final String status;
  final TextEditingController titleController;
  final TextEditingController slugController;
  final TextEditingController excerptController;
  final TextEditingController bodyController;
  final TextEditingController categoryController;
  final TextEditingController tagsController;
  final TextEditingController coverUrlController;
  final TextEditingController publishedAtController;
  final TextEditingController seoTitleController;
  final TextEditingController seoDescriptionController;
  final String? titleError;
  final String? bodyError;
  final Future<void> Function() onSavePost;
  final Future<void> Function() onUploadMedia;
  final ValueChanged<String?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('blog-editor-panel'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Editor', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  key: const Key('blog-cover-upload-button'),
                  onPressed: canWrite ? onUploadMedia : null,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload media'),
                ),
                FilledButton.icon(
                  onPressed: canWrite ? onSavePost : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Save post'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    key: const Key('blog-title-field'),
                    controller: titleController,
                    enabled: canWrite,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      errorText: titleError,
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: TextField(
                    key: const Key('blog-slug-field'),
                    controller: slugController,
                    enabled: canWrite,
                    decoration: const InputDecoration(labelText: 'Slug'),
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    key: const Key('blog-status-field'),
                    initialValue: status,
                    items: [
                      for (final item in _blogStatuses)
                        DropdownMenuItem(value: item, child: Text(item)),
                    ],
                    onChanged: canWrite ? onStatusChanged : null,
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    key: const Key('blog-category-field'),
                    controller: categoryController,
                    enabled: canWrite,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const Key('blog-tags-field'),
                    controller: tagsController,
                    enabled: canWrite,
                    decoration: const InputDecoration(
                      labelText: 'Tags',
                      helperText: 'comma separated',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('blog-excerpt-field'),
              controller: excerptController,
              enabled: canWrite,
              decoration: const InputDecoration(labelText: 'Excerpt'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('blog-published-at-field'),
              controller: publishedAtController,
              enabled: canWrite,
              decoration: const InputDecoration(
                labelText: 'Published at',
                helperText: 'ISO-8601 timestamp',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('blog-cover-url-field'),
              controller: coverUrlController,
              enabled: canWrite,
              decoration: const InputDecoration(labelText: 'Cover URL'),
            ),
            if (coverUrlController.text.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(coverUrlController.text),
            ],
            const SizedBox(height: 12),
            TextField(
              key: const Key('blog-seo-title-field'),
              controller: seoTitleController,
              enabled: canWrite,
              decoration: const InputDecoration(labelText: 'SEO title'),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('blog-seo-description-field'),
              controller: seoDescriptionController,
              enabled: canWrite,
              decoration: const InputDecoration(labelText: 'SEO description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Blog post body',
              textField: true,
              child: TextField(
                key: const Key('blog-body-field'),
                controller: bodyController,
                enabled: canWrite,
                decoration: InputDecoration(
                  labelText: 'Blog post body',
                  errorText: bodyError,
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostsTable extends StatelessWidget {
  const _PostsTable({
    required this.posts,
    required this.canWrite,
    required this.onEditPost,
  });

  final List<BlogPostItem> posts;
  final bool canWrite;
  final ValueChanged<BlogPostItem> onEditPost;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<BlogPostItem>(
      rows: posts,
      wideBreakpoint: 900,
      columns: const [
        DataColumn(label: Text('Action')),
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Category')),
        DataColumn(label: Text('Tags')),
        DataColumn(label: Text('Updated')),
      ],
      tableCells: (post) => [
        DataCell(
          _PostActions(post: post, canWrite: canWrite, onEditPost: onEditPost),
        ),
        DataCell(
          KeyedSubtree(
            key: Key('blog-post-row-${post.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text(post.title), Text(post.slug)],
            ),
          ),
        ),
        DataCell(Text(post.status)),
        DataCell(Text(post.categoryName ?? '-')),
        DataCell(Text(post.tagNames.join(', '))),
        DataCell(Text(_shortDate(post.updatedAt))),
      ],
      mobileBuilder: (context, post) => Card(
        key: Key('blog-post-row-${post.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(post.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(post.status),
              Text(post.categoryName ?? '-'),
              Text(post.tagNames.join(', ')),
            ],
          ),
          trailing: _PostActions(
            post: post,
            canWrite: canWrite,
            onEditPost: onEditPost,
          ),
        ),
      ),
    );
  }

  static String _shortDate(DateTime value) {
    return '${value.year}-${value.month}-${value.day}';
  }
}

class _PostActions extends StatelessWidget {
  const _PostActions({
    required this.post,
    required this.canWrite,
    required this.onEditPost,
  });

  final BlogPostItem post;
  final bool canWrite;
  final ValueChanged<BlogPostItem> onEditPost;

  @override
  Widget build(BuildContext context) {
    if (!canWrite) {
      return const SizedBox.shrink();
    }
    return TextButton(
      onPressed: () => onEditPost(post),
      child: Text('Edit ${post.title}'),
    );
  }
}
