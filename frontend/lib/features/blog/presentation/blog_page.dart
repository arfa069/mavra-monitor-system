import 'package:flutter/material.dart';

import '../../../core/files/file_service.dart';
import '../../../core/platform/platform_capabilities.dart';
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
  bool _editorDialogOpen = false;
  String _status = 'draft';
  String? _filterStatus;
  String? _titleError;
  String? _bodyError;
  String? _publishedAtError;

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
  final _canonicalUrlController = TextEditingController();
  final _ogImageUrlController = TextEditingController();
  final _filterKeywordController = TextEditingController();

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
    _canonicalUrlController.dispose();
    _ogImageUrlController.dispose();
    _filterKeywordController.dispose();
    super.dispose();
  }

  void _load() {
    final filter = BlogFilter(
      keyword: _blankToNull(_filterKeywordController.text),
      status: _filterStatus,
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

  Future<void> _newPost() async {
    _fillEditor(const BlogPostDraft.empty(), postId: null);
    await _showEditorDialog(title: 'New blog post');
  }

  Future<void> _editPost(BlogPostItem post) async {
    setState(() {
      _statusMessage = 'Loading ${post.title}...';
      _clearErrors();
    });
    try {
      final draft = await widget.repository.loadPostDraft(post.id);
      if (!mounted) {
        return;
      }
      _fillEditor(draft, postId: post.id);
      setState(() => _statusMessage = null);
      await _showEditorDialog(title: 'Edit blog post');
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Blog post load failed.');
      }
    }
  }

  void _fillEditor(BlogPostDraft draft, {required int? postId}) {
    _editingPostId = postId;
    _status = _knownStatus(draft.status);
    _clearErrors();
    _titleController.text = draft.title;
    _slugController.text = draft.slug;
    _excerptController.text = draft.excerpt ?? '';
    _bodyController.text = draft.body;
    _categoryController.text = draft.categoryName ?? '';
    _tagsController.text = draft.tagNames.join(', ');
    _coverUrlController.text = draft.coverUrl ?? '';
    _publishedAtController.text = draft.publishedAt?.toIso8601String() ?? '';
    _seoTitleController.text = draft.seoTitle ?? '';
    _seoDescriptionController.text = draft.seoDescription ?? '';
    _canonicalUrlController.text = draft.canonicalUrl ?? '';
    _ogImageUrlController.text = draft.ogImageUrl ?? '';
  }

  void _clearErrors() {
    _titleError = null;
    _bodyError = null;
    _publishedAtError = null;
  }

  Future<void> _showEditorDialog({required String title}) async {
    setState(() => _editorDialogOpen = true);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => Dialog(
            key: const Key('blog-editor-dialog'),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 980,
                maxHeight: MediaQuery.sizeOf(context).height - 32,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _BlogEditor(
                  title: title,
                  canWrite: _canWrite,
                  status: _status,
                  categories: _snapshot?.categories ?? const [],
                  tags: _snapshot?.tags ?? const [],
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
                  canonicalUrlController: _canonicalUrlController,
                  ogImageUrlController: _ogImageUrlController,
                  titleError: _titleError,
                  bodyError: _bodyError,
                  publishedAtError: _publishedAtError,
                  statusMessage: _statusMessage,
                  onClose: () => Navigator.of(dialogContext).pop(),
                  onSavePost: () async {
                    final saved = await _savePost();
                    setDialogState(() {});
                    if (saved && dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  onUploadMedia: () async {
                    await _uploadMedia();
                    setDialogState(() {});
                  },
                  onStatusChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _status = value);
                    }
                  },
                  onApplyBodyCommand: (command) {
                    _applyBodyCommand(command);
                    setDialogState(() {});
                  },
                  onUseCategory: (category) {
                    setDialogState(() => _categoryController.text = category);
                  },
                  onUseTag: (tag) {
                    setDialogState(() => _addTag(tag));
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _editorDialogOpen = false);
      }
    }
  }

  Future<bool> _savePost() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    final publishedAt = DateTime.tryParse(_publishedAtController.text.trim());
    setState(() {
      _titleError = title.isEmpty ? 'Title is required' : null;
      _bodyError = body.isEmpty ? 'Body is required' : null;
      _publishedAtError = _status == 'scheduled' && publishedAt == null
          ? 'Scheduled posts need a publish time'
          : null;
      _statusMessage = null;
    });
    if (_titleError != null ||
        _bodyError != null ||
        _publishedAtError != null) {
      return false;
    }

    final editor = BlogEditorValue.fromBody(_bodyController.text);
    final draft = BlogPostDraft(
      title: title,
      slug: _slugController.text.trim(),
      status: _status,
      body: _bodyController.text,
      editor: editor,
      excerpt: _blankToNull(_excerptController.text),
      categoryName: _blankToNull(_categoryController.text),
      tagNames: _splitTags(_tagsController.text),
      coverUrl: _blankToNull(_coverUrlController.text),
      publishedAt: publishedAt,
      seoTitle: _blankToNull(_seoTitleController.text),
      seoDescription: _blankToNull(_seoDescriptionController.text),
      canonicalUrl: _blankToNull(_canonicalUrlController.text),
      ogImageUrl: _blankToNull(_ogImageUrlController.text),
    );

    try {
      await widget.repository.savePost(draft, postId: _editingPostId);
      if (!mounted) {
        return false;
      }
      setState(() => _statusMessage = 'Saved ${draft.title}');
      _load();
      return true;
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Blog post save failed.');
      }
      return false;
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

  void _applyBodyCommand(_BodyCommand command) {
    switch (command) {
      case _BodyCommand.bold:
        _wrapBodySelection('<strong>', '</strong>', 'bold text');
      case _BodyCommand.italic:
        _wrapBodySelection('<em>', '</em>', 'italic text');
      case _BodyCommand.bulletList:
        _replaceBodySelection('<ul><li>List item</li></ul>');
      case _BodyCommand.numberedList:
        _replaceBodySelection('<ol><li>List item</li></ol>');
      case _BodyCommand.link:
        _wrapBodySelection('<a href="https://">', '</a>', 'link text');
      case _BodyCommand.image:
        _replaceBodySelection('<img src="/blog-media/" alt="">');
    }
  }

  void _wrapBodySelection(String prefix, String suffix, String placeholder) {
    final selection = _bodyController.selection;
    final text = _bodyController.text;
    if (!selection.isValid) {
      _replaceBodySelection('$prefix$placeholder$suffix');
      return;
    }
    final selected = selection.textInside(text);
    _replaceBodySelection(
      '$prefix${selected.isEmpty ? placeholder : selected}$suffix',
    );
  }

  void _replaceBodySelection(String replacement) {
    final text = _bodyController.text;
    final selection = _bodyController.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final next = text.replaceRange(start, end, replacement);
    _bodyController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _addTag(String tag) {
    final tags = _splitTags(_tagsController.text);
    if (!tags.contains(tag)) {
      tags.add(tag);
    }
    _tagsController.text = tags.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    if (!_canRead) {
      return const _BlogPermissionDenied();
    }

    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
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
                statusMessage: _editorDialogOpen ? null : _statusMessage,
                filterKeywordController: _filterKeywordController,
                filterStatus: _filterStatus,
                onNewPost: _newPost,
                onEditPost: _editPost,
                onApplyFilters: _load,
                onFilterStatusChanged: (value) {
                  setState(() => _filterStatus = value);
                },
              );
            },
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

const _statusLabels = <String, String>{
  'draft': 'Draft',
  'scheduled': 'Scheduled',
  'published': 'Published',
  'archived': 'Archived',
};

class _BlogPermissionDenied extends StatelessWidget {
  const _BlogPermissionDenied();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 44),
            SizedBox(height: 16),
            Text('没有权限访问 Blog Studio。'),
          ],
        ),
      ),
    );
  }
}

class _BlogContent extends StatelessWidget {
  const _BlogContent({
    required this.snapshot,
    required this.canWrite,
    required this.statusMessage,
    required this.filterKeywordController,
    required this.filterStatus,
    required this.onNewPost,
    required this.onEditPost,
    required this.onApplyFilters,
    required this.onFilterStatusChanged,
  });

  final BlogSnapshot snapshot;
  final bool canWrite;
  final String? statusMessage;
  final TextEditingController filterKeywordController;
  final String? filterStatus;
  final VoidCallback onNewPost;
  final ValueChanged<BlogPostItem> onEditPost;
  final VoidCallback onApplyFilters;
  final ValueChanged<String?> onFilterStatusChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BlogHeader(canWrite: canWrite, onNewPost: onNewPost),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          const SizedBox(height: 16),
          _BlogFilters(
            keywordController: filterKeywordController,
            status: filterStatus,
            onStatusChanged: onFilterStatusChanged,
            onApplyFilters: onApplyFilters,
          ),
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

class _BlogHeader extends StatelessWidget {
  const _BlogHeader({required this.canWrite, required this.onNewPost});

  final bool canWrite;
  final VoidCallback onNewPost;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public writing',
                  style: Theme.of(context).textTheme.labelMedium,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Blog Studio',
                  style: Theme.of(context).textTheme.headlineSmall,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (canWrite)
            FilledButton.icon(
              key: const Key('blog-new-post-button'),
              onPressed: onNewPost,
              icon: const Icon(Icons.add),
              label: const Text('New post'),
            ),
        ],
      ),
    );
  }
}

class _BlogFilters extends StatelessWidget {
  const _BlogFilters({
    required this.keywordController,
    required this.status,
    required this.onStatusChanged,
    required this.onApplyFilters,
  });

  final TextEditingController keywordController;
  final String? status;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onApplyFilters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            key: const Key('blog-search-field'),
            controller: keywordController,
            decoration: const InputDecoration(
              labelText: 'Search posts',
              prefixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => onApplyFilters(),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<String>(
            key: const Key('blog-status-filter'),
            initialValue: status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
              DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
              DropdownMenuItem(value: 'published', child: Text('Published')),
              DropdownMenuItem(value: 'archived', child: Text('Archived')),
            ],
            onChanged: onStatusChanged,
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
    required this.title,
    required this.canWrite,
    required this.status,
    required this.categories,
    required this.tags,
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
    required this.canonicalUrlController,
    required this.ogImageUrlController,
    required this.titleError,
    required this.bodyError,
    required this.publishedAtError,
    required this.statusMessage,
    required this.onClose,
    required this.onSavePost,
    required this.onUploadMedia,
    required this.onStatusChanged,
    required this.onApplyBodyCommand,
    required this.onUseCategory,
    required this.onUseTag,
  });

  final String title;
  final bool canWrite;
  final String status;
  final List<BlogCategory> categories;
  final List<BlogTag> tags;
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
  final TextEditingController canonicalUrlController;
  final TextEditingController ogImageUrlController;
  final String? titleError;
  final String? bodyError;
  final String? publishedAtError;
  final String? statusMessage;
  final VoidCallback onClose;
  final Future<void> Function() onSavePost;
  final Future<void> Function() onUploadMedia;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<_BodyCommand> onApplyBodyCommand;
  final ValueChanged<String> onUseCategory;
  final ValueChanged<String> onUseTag;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.article_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        if (statusMessage != null) ...[
          const SizedBox(height: 8),
          Text(statusMessage!),
        ],
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    SizedBox(
                      width: 520,
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
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        key: const Key('blog-status-field'),
                        initialValue: status,
                        items: [
                          for (final item in _blogStatuses)
                            DropdownMenuItem(
                              value: item,
                              child: Text(_statusLabels[item] ?? item),
                            ),
                        ],
                        onChanged: canWrite ? onStatusChanged : null,
                        decoration: const InputDecoration(labelText: 'Status'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 520,
                      child: TextField(
                        key: const Key('blog-slug-field'),
                        controller: slugController,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'Slug',
                          hintText: 'auto-generated-from-title',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: TextField(
                        key: const Key('blog-published-at-field'),
                        controller: publishedAtController,
                        enabled: canWrite,
                        decoration: InputDecoration(
                          labelText: 'Publish time',
                          helperText: 'ISO-8601 timestamp',
                          errorText: publishedAtError,
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
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    SizedBox(
                      width: 420,
                      child: _TaxonomyPickerField(
                        key: const Key('blog-category-field'),
                        controller: categoryController,
                        enabled: canWrite,
                        label: 'Category',
                        options: [
                          for (final category in categories) category.name,
                        ],
                        onUseOption: onUseCategory,
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: _TaxonomyPickerField(
                        key: const Key('blog-tags-field'),
                        controller: tagsController,
                        enabled: canWrite,
                        label: 'Tags',
                        helperText: 'comma separated',
                        options: [for (final tag in tags) tag.name],
                        onUseOption: onUseTag,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('blog-cover-url-field'),
                        controller: coverUrlController,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'Cover image',
                          hintText: '/blog-media/cover.webp',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton.icon(
                        key: const Key('blog-cover-upload-button'),
                        onPressed: canWrite ? onUploadMedia : null,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Upload media'),
                      ),
                    ),
                  ],
                ),
                if (coverUrlController.text.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(coverUrlController.text),
                ],
                const SizedBox(height: 12),
                _BlogBodyEditor(
                  canWrite: canWrite,
                  bodyController: bodyController,
                  bodyError: bodyError,
                  onApplyBodyCommand: onApplyBodyCommand,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 420,
                      child: TextField(
                        key: const Key('blog-seo-title-field'),
                        controller: seoTitleController,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'SEO title',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: TextField(
                        key: const Key('blog-seo-description-field'),
                        controller: seoDescriptionController,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'SEO description',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 420,
                      child: TextField(
                        key: const Key('blog-canonical-url-field'),
                        controller: canonicalUrlController,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'Canonical URL',
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 420,
                      child: TextField(
                        key: const Key('blog-og-image-field'),
                        controller: ogImageUrlController,
                        enabled: canWrite,
                        decoration: const InputDecoration(
                          labelText: 'Open Graph image',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(onPressed: onClose, child: const Text('Cancel')),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: canWrite ? onSavePost : null,
              icon: const Icon(Icons.save),
              label: const Text('Save post'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TaxonomyPickerField extends StatelessWidget {
  const _TaxonomyPickerField({
    super.key,
    required this.controller,
    required this.enabled,
    required this.label,
    required this.options,
    required this.onUseOption,
    this.helperText,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String? helperText;
  final List<String> options;
  final ValueChanged<String> onUseOption;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(labelText: label, helperText: helperText),
        ),
        if (options.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                ActionChip(
                  label: Text(option),
                  onPressed: enabled ? () => onUseOption(option) : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BlogBodyEditor extends StatelessWidget {
  const _BlogBodyEditor({
    required this.canWrite,
    required this.bodyController,
    required this.bodyError,
    required this.onApplyBodyCommand,
  });

  final bool canWrite;
  final TextEditingController bodyController;
  final String? bodyError;
  final ValueChanged<_BodyCommand> onApplyBodyCommand;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _ToolbarButton(
                  key: const Key('blog-editor-bold-button'),
                  tooltip: 'Bold',
                  icon: Icons.format_bold,
                  enabled: canWrite,
                  onPressed: () => onApplyBodyCommand(_BodyCommand.bold),
                ),
                _ToolbarButton(
                  key: const Key('blog-editor-italic-button'),
                  tooltip: 'Italic',
                  icon: Icons.format_italic,
                  enabled: canWrite,
                  onPressed: () => onApplyBodyCommand(_BodyCommand.italic),
                ),
                _ToolbarButton(
                  key: const Key('blog-editor-bullet-list-button'),
                  tooltip: 'Bullet list',
                  icon: Icons.format_list_bulleted,
                  enabled: canWrite,
                  onPressed: () => onApplyBodyCommand(_BodyCommand.bulletList),
                ),
                _ToolbarButton(
                  key: const Key('blog-editor-numbered-list-button'),
                  tooltip: 'Numbered list',
                  icon: Icons.format_list_numbered,
                  enabled: canWrite,
                  onPressed: () =>
                      onApplyBodyCommand(_BodyCommand.numberedList),
                ),
                _ToolbarButton(
                  key: const Key('blog-editor-link-button'),
                  tooltip: 'Link',
                  icon: Icons.link,
                  enabled: canWrite,
                  onPressed: () => onApplyBodyCommand(_BodyCommand.link),
                ),
                _ToolbarButton(
                  key: const Key('blog-editor-image-button'),
                  tooltip: 'Image URL',
                  icon: Icons.image_outlined,
                  enabled: canWrite,
                  onPressed: () => onApplyBodyCommand(_BodyCommand.image),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Semantics(
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
                  border: InputBorder.none,
                ),
                maxLines: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon),
    );
  }
}

enum _BodyCommand { bold, italic, bulletList, numberedList, link, image }

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
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Taxonomy')),
        DataColumn(label: Text('Published')),
        DataColumn(label: Text('Actions')),
      ],
      tableCells: (post) => [
        DataCell(
          KeyedSubtree(
            key: Key('blog-post-row-${post.id}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Text(post.title), Text('/${post.slug}')],
            ),
          ),
        ),
        DataCell(_StatusChip(status: post.status)),
        DataCell(_TaxonomyCell(post: post)),
        DataCell(Text(_publishedDate(post.publishedAt))),
        DataCell(
          _PostActions(post: post, canWrite: canWrite, onEditPost: onEditPost),
        ),
      ],
      mobileBuilder: (context, post) => Card(
        key: Key('blog-post-row-${post.id}'),
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(post.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('/${post.slug}'),
              _StatusChip(status: post.status),
              Text(_publishedDate(post.publishedAt)),
              if (post.categoryName != null) Text(post.categoryName!),
              for (final tag in post.tagNames) Text(tag),
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

  static String _publishedDate(DateTime? value) {
    if (value == null) {
      return 'Not set';
    }
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'scheduled' => Colors.blue,
      'published' => Colors.green,
      'archived' => Colors.orange,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.45)),
      label: Text(_statusLabels[status] ?? status),
    );
  }
}

class _TaxonomyCell extends StatelessWidget {
  const _TaxonomyCell({required this.post});

  final BlogPostItem post;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (post.categoryName != null) Chip(label: Text(post.categoryName!)),
        for (final tag in post.tagNames) Chip(label: Text(tag)),
        if (post.categoryName == null && post.tagNames.isEmpty) const Text('-'),
      ],
    );
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
    return TextButton.icon(
      onPressed: () => onEditPost(post),
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit'),
    );
  }
}
