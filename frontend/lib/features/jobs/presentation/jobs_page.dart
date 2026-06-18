import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_service.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_side_sheet.dart';
import '../domain/job_models.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({super.key, required this.repository, this.fileService});

  final JobsRepository repository;
  final FileService? fileService;

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  Future<JobsSnapshot>? _jobsFuture;
  JobsSnapshot? _snapshot;
  JobPageState? _jobPage;
  Object? _error;
  String? _statusMessage;
  int? _editingConfigId;
  bool _showConfigForm = false;
  int? _selectedResumeId;

  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  final _locationController = TextEditingController();
  final _platformController = TextEditingController();
  final _cronController = TextEditingController();
  final _jobKeywordFilterController = TextEditingController();
  final _jobPageSizeController = TextEditingController(text: '20');
  final _resumeNameController = TextEditingController();
  final _resumeTextController = TextEditingController();
  final _profileKeyController = TextEditingController();
  final _profilePlatformController = TextEditingController(text: 'boss');
  String _jobStatusFilter = 'all';

  FileService get _fileService =>
      widget.fileService ??
      FileService.forCapabilities(PlatformCapabilities.current());

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant JobsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) {
      _snapshot = null;
      _load();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    _locationController.dispose();
    _platformController.dispose();
    _cronController.dispose();
    _jobKeywordFilterController.dispose();
    _jobPageSizeController.dispose();
    _resumeNameController.dispose();
    _resumeTextController.dispose();
    _profileKeyController.dispose();
    _profilePlatformController.dispose();
    super.dispose();
  }

  void _load() {
    setState(() {
      _error = null;
      _jobsFuture = Future.sync(widget.repository.loadJobs)
        ..then((snapshot) {
          if (mounted) {
            setState(() {
              _snapshot = snapshot;
              _jobPage = snapshot.page.items.isEmpty
                  ? JobPageState(
                      items: snapshot.jobs,
                      page: 1,
                      pageSize: snapshot.jobs.length,
                      total: snapshot.jobs.length,
                    )
                  : snapshot.page;
            });
          }
        }).catchError((Object error) {
          if (mounted) {
            setState(() {
              _error = error;
            });
          }
        });
    });
  }

  void _newConfig() {
    setState(() {
      _editingConfigId = null;
      _showConfigForm = true;
      _nameController.clear();
      _keywordController.clear();
      _locationController.clear();
      _platformController.clear();
      _cronController.clear();
    });
  }

  void _editConfig(JobSearchConfig config) {
    setState(() {
      _editingConfigId = config.id;
      _showConfigForm = true;
      _nameController.text = config.name;
      _keywordController.text = config.keyword;
      _locationController.text = config.location;
      _platformController.text = config.platform;
      _cronController.text = config.cron;
    });
  }

  Future<void> _saveConfig() async {
    final draft = JobConfigDraft(
      name: _nameController.text.trim(),
      platform: _platformController.text.trim(),
      keyword: _keywordController.text.trim(),
      location: _locationController.text.trim(),
      cron: _cronController.text.trim(),
    );
    try {
      await widget.repository.saveConfig(draft, configId: _editingConfigId);
      if (!mounted) {
        return;
      }
      setState(() {
        _statusMessage = 'Saved ${draft.name}';
        _showConfigForm = false;
      });
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Save failed: $error');
      }
    }
  }

  Future<void> _applyJobFilters() async {
    final pageSize = int.tryParse(_jobPageSizeController.text.trim()) ?? 20;
    final query = JobListQuery(
      keyword: _emptyToNull(_jobKeywordFilterController.text),
      status: _jobStatusFilter == 'all' ? null : _jobStatusFilter,
      pageSize: pageSize,
    );

    try {
      final page = await widget.repository.listJobs(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _jobPage = page;
        _statusMessage = 'Loaded ${page.total} jobs';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Filter failed: $error');
      }
    }
  }

  Future<void> _showJobDetails(JobItem job) async {
    try {
      final detail = await widget.repository.loadJobDetail(job.id);
      if (!mounted) {
        return;
      }
      await MavraSideSheet.show<void>(
        context,
        title: 'Job details: ${detail.title}',
        child: _JobDetailPanel(
          detail: detail,
          onRequestMatchAnalysis: () {
            _requestMatchAnalysis(job);
            Navigator.of(context).maybePop();
          },
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Detail failed: $error');
      }
    }
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage, {
    bool reload = true,
  }) async {
    try {
      await action();
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = successMessage);
      if (reload) {
        _load();
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Action failed: $error');
      }
    }
  }

  Future<void> _deleteConfig(JobSearchConfig config) async {
    await _runAction(
      () => widget.repository.deleteConfig(config.id),
      'Deleted ${config.name}',
    );
  }

  Future<void> _requestCrawlAll() async {
    await _runAction(
      widget.repository.requestCrawlAll,
      'Job crawl requested',
      reload: false,
    );
  }

  Future<void> _requestCrawlConfig(JobSearchConfig config) async {
    await _runAction(
      () => widget.repository.requestCrawlConfig(config.id),
      'Crawl requested for ${config.name}',
      reload: false,
    );
  }

  Future<void> _requestMatchAnalysis(JobItem job) async {
    final resumes = _snapshot?.resumes ?? const <ResumeItem>[];
    if (resumes.isEmpty) {
      setState(() => _statusMessage = 'Add a resume before match analysis');
      return;
    }
    final resume = resumes.firstWhere(
      (resume) => resume.id == _selectedResumeId,
      orElse: () => resumes.first,
    );
    await _runAction(
      () => widget.repository.requestMatchAnalysis(job.id, resumeId: resume.id),
      'Match analysis requested',
      reload: false,
    );
  }

  Future<void> _uploadResume() async {
    try {
      final file = await _fileService.pickFile();
      if (file == null) {
        return;
      }
      await widget.repository.uploadResume(file);
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = 'Uploaded ${file.name}');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Upload failed: $error');
      }
    }
  }

  Future<void> _deleteResume(ResumeItem resume) async {
    await _runAction(
      () => widget.repository.deleteResume(resume.id),
      'Deleted ${resume.fileName}',
    );
  }

  Future<void> _createResume() async {
    _resumeNameController.clear();
    _resumeTextController.clear();
    await _showResumeDialog();
  }

  Future<void> _editResume(ResumeItem resume) async {
    _resumeNameController.text = resume.fileName;
    _resumeTextController.text = 'Existing resume text';
    await _showResumeDialog(resume: resume);
  }

  Future<void> _showResumeDialog({ResumeItem? resume}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resume == null ? 'Create resume' : 'Edit resume'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('job-resume-name-field'),
              controller: _resumeNameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('job-resume-text-field'),
              controller: _resumeTextController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Resume text'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('job-resume-save-button'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) {
      return;
    }

    final draft = ResumeDraft(
      name: _resumeNameController.text.trim(),
      resumeText: _resumeTextController.text.trim(),
    );
    if (resume == null) {
      await _runAction(
        () => widget.repository.createResume(draft),
        'Created ${draft.name}',
      );
      return;
    }
    await _runAction(
      () => widget.repository.updateResume(resume.id, draft),
      'Updated ${draft.name}',
    );
  }

  Future<void> _selectResume(ResumeItem resume) async {
    await _runAction(
      () => widget.repository.selectResumeForMatch(resume.id),
      'Selected ${resume.fileName}',
      reload: false,
    );
    if (mounted) {
      setState(() => _selectedResumeId = resume.id);
    }
  }

  Future<void> _importBackup() async {
    try {
      final file = await _fileService.pickFile();
      if (file == null) {
        return;
      }
      await widget.repository.importProfileBackup(file);
      if (!mounted) {
        return;
      }
      setState(() => _statusMessage = 'Imported ${file.name}');
      _load();
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Import failed: $error');
      }
    }
  }

  Future<void> _createProfile() async {
    _profileKeyController.clear();
    _profilePlatformController.text = 'boss';
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('job-profile-key-field'),
              controller: _profileKeyController,
              decoration: const InputDecoration(labelText: 'Profile key'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('job-profile-platform-field'),
              controller: _profilePlatformController,
              decoration: const InputDecoration(labelText: 'Platform'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (created != true) {
      return;
    }
    final profileKey = _profileKeyController.text.trim();
    final platform = _profilePlatformController.text.trim();
    if (profileKey.isEmpty || platform.isEmpty) {
      setState(() => _statusMessage = 'Profile key and platform are required');
      return;
    }
    await _runAction(
      () => widget.repository.createProfile(
        profileKey: profileKey,
        platform: platform,
      ),
      'Created $profileKey',
    );
  }

  Future<void> _renameProfile(CrawlProfileItem profile) async {
    final controller = TextEditingController(
      text: '${profile.profileKey}-copy',
    );
    final newProfileKey = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rename ${profile.profileKey}'),
        content: TextField(
          key: Key('job-profile-rename-${profile.profileKey}-field'),
          controller: controller,
          decoration: const InputDecoration(labelText: 'New profile key'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newProfileKey == null || newProfileKey.isEmpty) {
      return;
    }
    await _runAction(
      () => widget.repository.renameProfile(
        profileKey: profile.profileKey,
        newProfileKey: newProfileKey,
      ),
      'Renamed ${profile.profileKey}',
    );
  }

  Future<void> _updateProfileStatus(
    CrawlProfileItem profile,
    String status,
  ) async {
    await _runAction(
      () => widget.repository.updateProfileStatus(
        profileKey: profile.profileKey,
        status: status,
      ),
      'Updated ${profile.profileKey}',
    );
  }

  Future<void> _copyProfile(CrawlProfileItem profile) async {
    await _runAction(
      () => widget.repository.copyProfile(profile.profileKey),
      'Copied ${profile.profileKey}',
    );
  }

  Future<void> _deleteProfile(CrawlProfileItem profile) async {
    await _runAction(
      () => widget.repository.deleteProfile(profile.profileKey),
      'Deleted ${profile.profileKey}',
    );
  }

  Future<void> _releaseStaleProfile(CrawlProfileItem profile) async {
    await _runAction(
      () => widget.repository.releaseStaleProfile(profile.profileKey),
      'Released ${profile.profileKey}',
      reload: false,
    );
  }

  Future<void> _openProfileLoginSession(CrawlProfileItem profile) async {
    await _runAction(
      () => widget.repository.openProfileLoginSession(
        profileKey: profile.profileKey,
        platform: profile.platform,
      ),
      'Login session opened for ${profile.profileKey}',
      reload: false,
    );
  }

  Future<void> _closeProfileLoginSession(CrawlProfileItem profile) async {
    await _runAction(
      () => widget.repository.closeProfileLoginSession(profile.profileKey),
      'Login session closed for ${profile.profileKey}',
      reload: false,
    );
  }

  Future<void> _testProfile(CrawlProfileItem profile) async {
    await _runAction(
      () => widget.repository.testProfile(
        profileKey: profile.profileKey,
        platform: profile.platform,
      ),
      'Profile test requested for ${profile.profileKey}',
      reload: false,
    );
  }

  Future<void> _exportBackup(String profileKey) async {
    try {
      final backup = await widget.repository.exportProfileBackup(profileKey);
      await _fileService.saveBytes(
        suggestedName: backup.fileName,
        bytes: backup.bytes,
      );
      if (mounted) {
        setState(() => _statusMessage = 'Exported ${backup.fileName}');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = 'Export failed: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.today, label: 'Today'),
          AdaptiveDestination(icon: Icons.work, label: 'Jobs'),
          AdaptiveDestination(icon: Icons.inventory_2, label: 'Products'),
          AdaptiveDestination(icon: Icons.analytics, label: 'Analytics'),
        ],
        selectedIndex: 1,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/today');
            case 2:
              context.go('/products');
            case 3:
              context.go('/analytics');
          }
        },
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FutureBuilder<JobsSnapshot>(
              future: _jobsFuture,
              builder: (context, snapshot) {
                if (_error != null) {
                  return const Center(child: Text('Jobs unavailable'));
                }
                if (snapshot.connectionState != ConnectionState.done &&
                    _snapshot == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _JobsContent(
                  snapshot: _snapshot ?? const JobsSnapshot.empty(),
                  jobPage: _jobPage,
                  statusMessage: _statusMessage,
                  showConfigForm: _showConfigForm,
                  selectedResumeId: _selectedResumeId,
                  nameController: _nameController,
                  keywordController: _keywordController,
                  locationController: _locationController,
                  platformController: _platformController,
                  cronController: _cronController,
                  jobKeywordFilterController: _jobKeywordFilterController,
                  jobPageSizeController: _jobPageSizeController,
                  jobStatusFilter: _jobStatusFilter,
                  onJobStatusFilterChanged: (value) =>
                      setState(() => _jobStatusFilter = value),
                  onApplyJobFilters: _applyJobFilters,
                  onNewConfig: _newConfig,
                  onSaveConfig: _saveConfig,
                  onEditConfig: _editConfig,
                  onDeleteConfig: _deleteConfig,
                  onRequestCrawlAll: _requestCrawlAll,
                  onRequestCrawlConfig: _requestCrawlConfig,
                  onRequestMatchAnalysis: _requestMatchAnalysis,
                  onShowJobDetails: _showJobDetails,
                  onUploadResume: _uploadResume,
                  onCreateResume: _createResume,
                  onEditResume: _editResume,
                  onDeleteResume: _deleteResume,
                  onSelectResume: _selectResume,
                  onImportBackup: _importBackup,
                  onCreateProfile: _createProfile,
                  onRenameProfile: _renameProfile,
                  onUpdateProfileStatus: _updateProfileStatus,
                  onCopyProfile: _copyProfile,
                  onDeleteProfile: _deleteProfile,
                  onReleaseStaleProfile: _releaseStaleProfile,
                  onOpenProfileLoginSession: _openProfileLoginSession,
                  onCloseProfileLoginSession: _closeProfileLoginSession,
                  onTestProfile: _testProfile,
                  onExportBackup: _exportBackup,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _JobsContent extends StatelessWidget {
  const _JobsContent({
    required this.snapshot,
    required this.jobPage,
    required this.statusMessage,
    required this.showConfigForm,
    required this.selectedResumeId,
    required this.nameController,
    required this.keywordController,
    required this.locationController,
    required this.platformController,
    required this.cronController,
    required this.jobKeywordFilterController,
    required this.jobPageSizeController,
    required this.jobStatusFilter,
    required this.onJobStatusFilterChanged,
    required this.onApplyJobFilters,
    required this.onNewConfig,
    required this.onSaveConfig,
    required this.onEditConfig,
    required this.onDeleteConfig,
    required this.onRequestCrawlAll,
    required this.onRequestCrawlConfig,
    required this.onRequestMatchAnalysis,
    required this.onShowJobDetails,
    required this.onUploadResume,
    required this.onCreateResume,
    required this.onEditResume,
    required this.onDeleteResume,
    required this.onSelectResume,
    required this.onImportBackup,
    required this.onCreateProfile,
    required this.onRenameProfile,
    required this.onUpdateProfileStatus,
    required this.onCopyProfile,
    required this.onDeleteProfile,
    required this.onReleaseStaleProfile,
    required this.onOpenProfileLoginSession,
    required this.onCloseProfileLoginSession,
    required this.onTestProfile,
    required this.onExportBackup,
  });

  final JobsSnapshot snapshot;
  final JobPageState? jobPage;
  final String? statusMessage;
  final bool showConfigForm;
  final int? selectedResumeId;
  final TextEditingController nameController;
  final TextEditingController keywordController;
  final TextEditingController locationController;
  final TextEditingController platformController;
  final TextEditingController cronController;
  final TextEditingController jobKeywordFilterController;
  final TextEditingController jobPageSizeController;
  final String jobStatusFilter;
  final ValueChanged<String> onJobStatusFilterChanged;
  final Future<void> Function() onApplyJobFilters;
  final VoidCallback onNewConfig;
  final Future<void> Function() onSaveConfig;
  final ValueChanged<JobSearchConfig> onEditConfig;
  final ValueChanged<JobSearchConfig> onDeleteConfig;
  final Future<void> Function() onRequestCrawlAll;
  final ValueChanged<JobSearchConfig> onRequestCrawlConfig;
  final ValueChanged<JobItem> onRequestMatchAnalysis;
  final ValueChanged<JobItem> onShowJobDetails;
  final VoidCallback onUploadResume;
  final VoidCallback onCreateResume;
  final ValueChanged<ResumeItem> onEditResume;
  final ValueChanged<ResumeItem> onDeleteResume;
  final ValueChanged<ResumeItem> onSelectResume;
  final VoidCallback onImportBackup;
  final VoidCallback onCreateProfile;
  final ValueChanged<CrawlProfileItem> onRenameProfile;
  final void Function(CrawlProfileItem profile, String status)
  onUpdateProfileStatus;
  final ValueChanged<CrawlProfileItem> onCopyProfile;
  final ValueChanged<CrawlProfileItem> onDeleteProfile;
  final ValueChanged<CrawlProfileItem> onReleaseStaleProfile;
  final ValueChanged<CrawlProfileItem> onOpenProfileLoginSession;
  final ValueChanged<CrawlProfileItem> onCloseProfileLoginSession;
  final ValueChanged<CrawlProfileItem> onTestProfile;
  final ValueChanged<String> onExportBackup;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jobs', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: onImportBackup,
                icon: const Icon(Icons.archive),
                label: const Text('Import backup'),
              ),
              TextButton.icon(
                onPressed: onUploadResume,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Upload resume'),
              ),
              TextButton.icon(
                key: const Key('job-crawl-all-button'),
                onPressed: onRequestCrawlAll,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Run crawl'),
              ),
              FilledButton.icon(
                onPressed: onNewConfig,
                icon: const Icon(Icons.add),
                label: const Text('New config'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _JobTabStrip(),
          if (statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(statusMessage!),
          ],
          if (showConfigForm) ...[
            const SizedBox(height: 12),
            _JobConfigForm(
              nameController: nameController,
              keywordController: keywordController,
              locationController: locationController,
              platformController: platformController,
              cronController: cronController,
              onSave: onSaveConfig,
            ),
          ],
          const SizedBox(height: 16),
          _JobFilters(
            keywordController: jobKeywordFilterController,
            pageSizeController: jobPageSizeController,
            statusFilter: jobStatusFilter,
            onStatusFilterChanged: onJobStatusFilterChanged,
            onApplyFilters: onApplyJobFilters,
          ),
          const SizedBox(height: 12),
          if (snapshot.jobs.isEmpty)
            const Center(child: Text('No jobs yet'))
          else
            _JobsTable(
              jobs: jobPage?.items ?? snapshot.jobs,
              onShowDetails: onShowJobDetails,
            ),
          const SizedBox(height: 20),
          _Section(
            title: 'Search configs',
            emptyText: 'No job configs yet',
            children: [
              for (final config in snapshot.configs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tune),
                  title: Text(config.name),
                  subtitle: Text('${config.platform} - ${config.keyword}'),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        key: Key('job-crawl-config-${config.id}-button'),
                        tooltip: 'Run crawl ${config.name}',
                        onPressed: () => onRequestCrawlConfig(config),
                        icon: const Icon(Icons.play_circle),
                      ),
                      TextButton(
                        onPressed: () => onEditConfig(config),
                        child: Text('Edit ${config.name}'),
                      ),
                      IconButton(
                        key: Key('job-delete-config-${config.id}-button'),
                        tooltip: 'Delete ${config.name}',
                        onPressed: () => onDeleteConfig(config),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _Section(
            title: 'Schedule',
            emptyText: 'No schedules yet',
            children: [
              for (final config in snapshot.configs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(config.cron),
                  subtitle: Text(config.location),
                ),
            ],
          ),
          _Section(
            title: 'Resume manager',
            emptyText: 'No resumes yet',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('job-resume-create-button'),
                  onPressed: onCreateResume,
                  icon: const Icon(Icons.note_add),
                  label: const Text('Create resume'),
                ),
              ),
              for (final resume in snapshot.resumes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description),
                  title: Text(resume.fileName),
                  subtitle: Text(
                    selectedResumeId == resume.id
                        ? 'Selected for matching'
                        : resume.updatedAt.toIso8601String(),
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        key: Key('job-resume-select-${resume.id}-button'),
                        tooltip: 'Select ${resume.fileName}',
                        onPressed: () => onSelectResume(resume),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                      IconButton(
                        key: Key('job-resume-edit-${resume.id}-button'),
                        tooltip: 'Edit ${resume.fileName}',
                        onPressed: () => onEditResume(resume),
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        key: Key('job-resume-delete-${resume.id}-button'),
                        tooltip: 'Delete ${resume.fileName}',
                        onPressed: () => onDeleteResume(resume),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          _Section(
            title: 'Match results',
            emptyText: 'No match results yet',
            children: [
              for (final match in snapshot.matches)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.fact_check),
                  title: Text(match.score),
                  subtitle: Text('${match.jobTitle} - ${match.reason}'),
                ),
            ],
          ),
          _Section(
            title: 'Profile management',
            emptyText: 'No profiles yet',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('job-profile-create-button'),
                  onPressed: onCreateProfile,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create profile'),
                ),
              ),
              for (final profile in snapshot.profiles)
                _ProfileTile(
                  profile: profile,
                  onExportBackup: onExportBackup,
                  onRenameProfile: onRenameProfile,
                  onUpdateProfileStatus: onUpdateProfileStatus,
                  onCopyProfile: onCopyProfile,
                  onDeleteProfile: onDeleteProfile,
                  onReleaseStaleProfile: onReleaseStaleProfile,
                  onOpenProfileLoginSession: onOpenProfileLoginSession,
                  onCloseProfileLoginSession: onCloseProfileLoginSession,
                  onTestProfile: onTestProfile,
                ),
            ],
          ),
          _Section(
            title: 'Crawl logs',
            emptyText: 'No crawl logs yet',
            children: [
              for (final log in snapshot.crawlLogs)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.receipt_long),
                  title: Text(log.message),
                  subtitle: Text(log.status),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JobConfigForm extends StatelessWidget {
  const _JobConfigForm({
    required this.nameController,
    required this.keywordController,
    required this.locationController,
    required this.platformController,
    required this.cronController,
    required this.onSave,
  });

  final TextEditingController nameController;
  final TextEditingController keywordController;
  final TextEditingController locationController;
  final TextEditingController platformController;
  final TextEditingController cronController;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Config form', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              key: const Key('job-config-name-field'),
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('job-keyword-field'),
              controller: keywordController,
              decoration: const InputDecoration(labelText: 'Keyword'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('job-location-field'),
              controller: locationController,
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('job-platform-field'),
              controller: platformController,
              decoration: const InputDecoration(labelText: 'Platform'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('job-cron-field'),
              controller: cronController,
              decoration: const InputDecoration(labelText: 'Cron'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onSave,
              icon: const Icon(Icons.save),
              label: const Text('Save config'),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobTabStrip extends StatelessWidget {
  const _JobTabStrip();

  static const _tabs = [
    (key: 'job-tab-configs', label: 'Configs', icon: Icons.tune),
    (key: 'job-tab-jobs', label: 'Jobs', icon: Icons.work),
    (key: 'job-tab-matches', label: 'Match Results', icon: Icons.fact_check),
    (key: 'job-tab-resumes', label: 'Resumes', icon: Icons.description),
    (key: 'job-tab-profiles', label: 'Profiles', icon: Icons.person_search),
    (key: 'job-tab-logs', label: 'Crawl Logs', icon: Icons.receipt_long),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in _tabs)
          ActionChip(
            key: Key(tab.key),
            avatar: Icon(tab.icon, size: 16),
            label: Text(tab.label),
            onPressed: () {},
          ),
      ],
    );
  }
}

class _JobFilters extends StatelessWidget {
  const _JobFilters({
    required this.keywordController,
    required this.pageSizeController,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    required this.onApplyFilters,
  });

  final TextEditingController keywordController;
  final TextEditingController pageSizeController;
  final String statusFilter;
  final ValueChanged<String> onStatusFilterChanged;
  final Future<void> Function() onApplyFilters;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            key: const Key('job-keyword-filter'),
            controller: keywordController,
            decoration: const InputDecoration(
              labelText: 'Keyword',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            key: const Key('job-page-size-field'),
            controller: pageSizeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Page size'),
          ),
        ),
        SegmentedButton<String>(
          key: const Key('job-status-filter'),
          segments: const [
            ButtonSegment(value: 'all', label: Text('All')),
            ButtonSegment(value: 'active', label: Text('Active')),
            ButtonSegment(value: 'inactive', label: Text('Inactive')),
          ],
          selected: {statusFilter},
          onSelectionChanged: (selection) =>
              onStatusFilterChanged(selection.first),
        ),
        FilledButton.icon(
          key: const Key('job-apply-filters-button'),
          onPressed: onApplyFilters,
          icon: const Icon(Icons.filter_alt),
          label: const Text('Apply'),
        ),
      ],
    );
  }
}

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.jobs, required this.onShowDetails});

  final List<JobItem> jobs;
  final ValueChanged<JobItem> onShowDetails;

  @override
  Widget build(BuildContext context) {
    return MavraResponsiveDataView<JobItem>(
      rows: jobs,
      wideBreakpoint: 960,
      columns: const [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Company')),
        DataColumn(label: Text('Platform')),
        DataColumn(label: Text('Location')),
        DataColumn(label: Text('Status')),
        DataColumn(label: Text('Actions')),
      ],
      tableCells: (job) => [
        DataCell(
          SizedBox(
            width: 260,
            child: Text(job.title, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text(job.company)),
        DataCell(Text(job.platform)),
        DataCell(Text(job.location)),
        DataCell(Text(job.status)),
        DataCell(
          IconButton(
            key: Key('job-detail-${job.id}-button'),
            tooltip: 'View ${job.title}',
            onPressed: () => onShowDetails(job),
            icon: const Icon(Icons.open_in_new),
          ),
        ),
      ],
      mobileBuilder: (context, job) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: const Icon(Icons.work),
          title: Text(job.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.company),
              Text('${job.location} - ${job.platform}'),
            ],
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              Text(job.status),
              IconButton(
                key: Key('job-detail-${job.id}-button'),
                tooltip: 'View ${job.title}',
                onPressed: () => onShowDetails(job),
                icon: const Icon(Icons.open_in_new),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JobDetailPanel extends StatelessWidget {
  const _JobDetailPanel({
    required this.detail,
    required this.onRequestMatchAnalysis,
  });

  final JobDetail detail;
  final VoidCallback onRequestMatchAnalysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(detail.company, style: Theme.of(context).textTheme.titleMedium),
        if (detail.url != null) ...[
          const SizedBox(height: 8),
          Text(detail.url!),
        ],
        if (detail.description != null) ...[
          const SizedBox(height: 12),
          Text(detail.description!),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          key: Key('job-match-${detail.id}-button'),
          onPressed: onRequestMatchAnalysis,
          icon: const Icon(Icons.psychology),
          label: const Text('Run match'),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.onExportBackup,
    required this.onRenameProfile,
    required this.onUpdateProfileStatus,
    required this.onCopyProfile,
    required this.onDeleteProfile,
    required this.onReleaseStaleProfile,
    required this.onOpenProfileLoginSession,
    required this.onCloseProfileLoginSession,
    required this.onTestProfile,
  });

  final CrawlProfileItem profile;
  final ValueChanged<String> onExportBackup;
  final ValueChanged<CrawlProfileItem> onRenameProfile;
  final void Function(CrawlProfileItem profile, String status)
  onUpdateProfileStatus;
  final ValueChanged<CrawlProfileItem> onCopyProfile;
  final ValueChanged<CrawlProfileItem> onDeleteProfile;
  final ValueChanged<CrawlProfileItem> onReleaseStaleProfile;
  final ValueChanged<CrawlProfileItem> onOpenProfileLoginSession;
  final ValueChanged<CrawlProfileItem> onCloseProfileLoginSession;
  final ValueChanged<CrawlProfileItem> onTestProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_search),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    profile.profileKey,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('${profile.platform} - ${profile.status}'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () => onExportBackup(profile.profileKey),
                  child: Text('Export backup ${profile.profileKey}'),
                ),
                IconButton(
                  key: Key('job-profile-rename-${profile.profileKey}-button'),
                  tooltip: 'Rename ${profile.profileKey}',
                  onPressed: () => onRenameProfile(profile),
                  icon: const Icon(Icons.drive_file_rename_outline),
                ),
                IconButton(
                  key: Key('job-profile-enable-${profile.profileKey}-button'),
                  tooltip: 'Mark available ${profile.profileKey}',
                  onPressed: () => onUpdateProfileStatus(profile, 'available'),
                  icon: const Icon(Icons.check_circle_outline),
                ),
                IconButton(
                  key: Key('job-profile-disable-${profile.profileKey}-button'),
                  tooltip: 'Disable ${profile.profileKey}',
                  onPressed: () => onUpdateProfileStatus(profile, 'disabled'),
                  icon: const Icon(Icons.block),
                ),
                IconButton(
                  key: Key('job-profile-copy-${profile.profileKey}-button'),
                  tooltip: 'Copy ${profile.profileKey}',
                  onPressed: () => onCopyProfile(profile),
                  icon: const Icon(Icons.copy),
                ),
                IconButton(
                  key: Key('job-profile-release-${profile.profileKey}-button'),
                  tooltip: 'Release stale ${profile.profileKey}',
                  onPressed: () => onReleaseStaleProfile(profile),
                  icon: const Icon(Icons.lock_open),
                ),
                IconButton(
                  key: Key('job-profile-login-${profile.profileKey}-button'),
                  tooltip: 'Open login session ${profile.profileKey}',
                  onPressed: () => onOpenProfileLoginSession(profile),
                  icon: const Icon(Icons.login),
                ),
                IconButton(
                  key: Key(
                    'job-profile-close-login-${profile.profileKey}-button',
                  ),
                  tooltip: 'Close login session ${profile.profileKey}',
                  onPressed: () => onCloseProfileLoginSession(profile),
                  icon: const Icon(Icons.logout),
                ),
                IconButton(
                  key: Key('job-profile-test-${profile.profileKey}-button'),
                  tooltip: 'Test ${profile.profileKey}',
                  onPressed: () => onTestProfile(profile),
                  icon: const Icon(Icons.science),
                ),
                IconButton(
                  key: Key('job-profile-delete-${profile.profileKey}-button'),
                  tooltip: 'Delete ${profile.profileKey}',
                  onPressed: () => onDeleteProfile(profile),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.emptyText,
    required this.children,
  });

  final String title;
  final String emptyText;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (children.isEmpty) Text(emptyText) else ...children,
        ],
      ),
    );
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
