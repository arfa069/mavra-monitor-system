import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_service.dart';
import '../../../core/notifications/mavra_notifier.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
import '../../../core/widgets/mavra_page_banner.dart';
import '../../../core/widgets/mavra_responsive_data_view.dart';
import '../../../core/widgets/mavra_side_sheet.dart';
import '../../../core/widgets/mavra_style_helpers.dart';
import '../domain/job_models.dart';

class JobsPage extends StatefulWidget {
  const JobsPage({
    super.key,
    required this.repository,
    this.fileService,
    this.permissions,
  });

  final JobsRepository repository;
  final FileService? fileService;
  final Set<String>? permissions;

  @override
  State<JobsPage> createState() => _JobsPageState();
}

class _JobsPageState extends State<JobsPage> {
  Future<JobsSnapshot>? _jobsFuture;
  JobsSnapshot? _snapshot;
  JobPageState? _jobPage;
  Object? _error;
  int? _editingConfigId;
  int? _selectedResumeId;
  _JobWorkbenchTab _activeTab = _JobWorkbenchTab.jobsList;

  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _configProfileKeyController = TextEditingController();
  final _keywordController = TextEditingController();
  final _locationController = TextEditingController();
  final _platformController = TextEditingController();
  final _cronController = TextEditingController();
  final _salaryMinController = TextEditingController();
  final _salaryMaxController = TextEditingController();
  final _experienceController = TextEditingController();
  final _educationController = TextEditingController();
  final _deactivationThresholdController = TextEditingController(text: '3');
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

  bool get _canRunCrawl =>
      widget.permissions == null ||
      widget.permissions!.contains('crawl:execute');

  bool get _canImportExportBackups =>
      widget.permissions == null ||
      widget.permissions!.contains('config:write');

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
    _urlController.dispose();
    _configProfileKeyController.dispose();
    _keywordController.dispose();
    _locationController.dispose();
    _platformController.dispose();
    _cronController.dispose();
    _salaryMinController.dispose();
    _salaryMaxController.dispose();
    _experienceController.dispose();
    _educationController.dispose();
    _deactivationThresholdController.dispose();
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
              final fallbackPageSize =
                  int.tryParse(_jobPageSizeController.text.trim()) ?? 20;
              final pageState = snapshot.page.items.isEmpty
                  ? JobPageState(
                      items: snapshot.jobs,
                      page: 1,
                      pageSize: fallbackPageSize,
                      total: snapshot.jobs.length,
                    )
                  : snapshot.page;
              _jobPage = pageState;
              _jobPageSizeController.text = '${pageState.pageSize}';
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

  Future<void> _newConfig() async {
    _editingConfigId = null;
    _nameController.clear();
    _urlController.clear();
    _configProfileKeyController.text = 'default';
    _keywordController.clear();
    _locationController.clear();
    _platformController.text = 'boss';
    _cronController.clear();
    _salaryMinController.clear();
    _salaryMaxController.clear();
    _experienceController.clear();
    _educationController.clear();
    _deactivationThresholdController.text = '3';
    await _showConfigDialog();
  }

  Future<void> _editConfig(JobSearchConfig config) async {
    _editingConfigId = config.id;
    _nameController.text = config.name;
    _urlController.text = config.url ?? '';
    _configProfileKeyController.text = config.profileKey ?? 'default';
    _keywordController.text = config.keyword;
    _locationController.text = config.cityCode ?? config.location;
    _platformController.text = config.platform;
    _cronController.text = config.cron == 'Disabled' ? '' : config.cron;
    _salaryMinController.text = config.salaryMin?.toString() ?? '';
    _salaryMaxController.text = config.salaryMax?.toString() ?? '';
    _experienceController.text = config.experience ?? '';
    _educationController.text = config.education ?? '';
    _deactivationThresholdController.text = config.deactivationThreshold
        .toString();
    await _showConfigDialog(config: config);
  }

  Future<void> _showConfigDialog({JobSearchConfig? config}) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(config == null ? 'Add Job Config' : 'Edit Job Config'),
        content: SizedBox(
          width: 720,
          child: SingleChildScrollView(
            child: _JobConfigForm(
              nameController: _nameController,
              urlController: _urlController,
              profileKeyController: _configProfileKeyController,
              keywordController: _keywordController,
              locationController: _locationController,
              platformController: _platformController,
              cronController: _cronController,
              salaryMinController: _salaryMinController,
              salaryMaxController: _salaryMaxController,
              experienceController: _experienceController,
              educationController: _educationController,
              deactivationThresholdController: _deactivationThresholdController,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () async {
              await _saveConfig();
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('Save config'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfig() async {
    final draft = JobConfigDraft(
      name: _nameController.text.trim(),
      platform: _platformController.text.trim(),
      keyword: _keywordController.text.trim(),
      location: _locationController.text.trim(),
      cron: _cronController.text.trim(),
      url: _emptyToNull(_urlController.text),
      profileKey: _emptyToNull(_configProfileKeyController.text),
      cityCode: _emptyToNull(_locationController.text),
      salaryMin: int.tryParse(_salaryMinController.text.trim()),
      salaryMax: int.tryParse(_salaryMaxController.text.trim()),
      experience: _emptyToNull(_experienceController.text),
      education: _emptyToNull(_educationController.text),
      deactivationThreshold:
          int.tryParse(_deactivationThresholdController.text.trim()) ?? 3,
    );
    try {
      await widget.repository.saveConfig(draft, configId: _editingConfigId);
      if (!mounted) {
        return;
      }
      MavraNotifier.success('Saved ${draft.name}');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Save failed: $error');
      }
    }
  }

  Future<void> _loadJobPage({required int page}) async {
    final pageSize = int.tryParse(_jobPageSizeController.text.trim()) ?? 20;
    final query = JobListQuery(
      keyword: _emptyToNull(_jobKeywordFilterController.text),
      status: _jobStatusFilter == 'all' ? null : _jobStatusFilter,
      page: page,
      pageSize: pageSize,
    );

    try {
      final page = await widget.repository.listJobs(query);
      if (!mounted) {
        return;
      }
      setState(() {
        _jobPage = page;
      });
      MavraNotifier.info('Loaded ${page.total} jobs');
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Filter failed: $error');
      }
    }
  }

  Future<void> _applyJobFilters() => _loadJobPage(page: 1);

  Future<void> _changeJobPage(int page) => _loadJobPage(page: page);

  Future<void> _showJobDetails(JobItem job) async {
    late final JobDetail detail;
    var usedFallback = false;
    try {
      detail = await widget.repository.loadJobDetail(job.id);
    } catch (_) {
      detail = JobDetail(
        id: job.id,
        title: job.title,
        company: job.company,
        salary: job.salary,
        location: job.location,
        status: job.status,
        updatedAt: job.updatedAt,
      );
      usedFallback = true;
    }
    if (!mounted) {
      return;
    }
    try {
      await MavraSideSheet.show<void>(
        context,
        title: 'Job details: ${detail.title}',
        child: _JobDetailPanel(
          detail: detail,
          fallbackMessage: usedFallback
              ? 'Showing list data because full details are unavailable.'
              : null,
          onRequestMatchAnalysis: _canRunCrawl
              ? () {
                  _requestMatchAnalysis(job);
                  Navigator.of(context).maybePop();
                }
              : null,
        ),
      );
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Detail failed: $error');
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
      MavraNotifier.success(successMessage);
      if (reload) {
        _load();
      }
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Action failed: $error');
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
      MavraNotifier.warning('Add a resume before match analysis');
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
      MavraNotifier.success('Uploaded ${file.name}');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Upload failed: $error');
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
    _resumeTextController.text = resume.resumeText;
    await _showResumeDialog(resume: resume);
  }

  Future<void> _viewResume(ResumeItem resume) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('View: ${resume.fileName}'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: SelectableText(
              resume.resumeText.isEmpty
                  ? 'No resume content'
                  : resume.resumeText,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _showResumeDialog({ResumeItem? resume}) async {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.72;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          resume == null ? 'Create resume' : 'Edit: ${resume.fileName}',
        ),
        content: SizedBox(
          width: 860,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: dialogHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const Key('job-resume-name-field'),
                  controller: _resumeNameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 360,
                  child: TextField(
                    key: const Key('job-resume-text-field'),
                    controller: _resumeTextController,
                    expands: true,
                    maxLines: null,
                    minLines: null,
                    textAlignVertical: TextAlignVertical.top,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'Resume text',
                    ),
                  ),
                ),
              ],
            ),
          ),
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
      MavraNotifier.success('Imported ${file.name}');
      _load();
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Import failed: $error');
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
      MavraNotifier.warning('Profile key and platform are required');
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
        MavraNotifier.success('Exported ${backup.fileName}');
      }
    } catch (error) {
      if (mounted) {
        MavraNotifier.error('Export failed: $error');
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
                  canRunCrawl: _canRunCrawl,
                  canImportExportBackups: _canImportExportBackups,
                  selectedResumeId: _selectedResumeId,
                  jobKeywordFilterController: _jobKeywordFilterController,
                  jobPageSizeController: _jobPageSizeController,
                  jobStatusFilter: _jobStatusFilter,
                  activeTab: _activeTab,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                  onJobStatusFilterChanged: (value) =>
                      setState(() => _jobStatusFilter = value),
                  onApplyJobFilters: _applyJobFilters,
                  onJobPageChanged: _changeJobPage,
                  onNewConfig: _newConfig,
                  onEditConfig: _editConfig,
                  onDeleteConfig: _deleteConfig,
                  onRequestCrawlAll: _requestCrawlAll,
                  onRequestCrawlConfig: _requestCrawlConfig,
                  onRequestMatchAnalysis: _requestMatchAnalysis,
                  onShowJobDetails: _showJobDetails,
                  onUploadResume: _uploadResume,
                  onCreateResume: _createResume,
                  onViewResume: _viewResume,
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

enum _JobWorkbenchTab { jobsList, configs, profiles, resumes, matches, logs }

extension _JobWorkbenchTabMeta on _JobWorkbenchTab {
  String get key => switch (this) {
    _JobWorkbenchTab.jobsList => 'job-tab-jobs-list',
    _JobWorkbenchTab.configs => 'job-tab-configs',
    _JobWorkbenchTab.profiles => 'job-tab-profiles',
    _JobWorkbenchTab.resumes => 'job-tab-resumes',
    _JobWorkbenchTab.matches => 'job-tab-matches',
    _JobWorkbenchTab.logs => 'job-tab-logs',
  };

  String get label => switch (this) {
    _JobWorkbenchTab.jobsList => 'Jobs List',
    _JobWorkbenchTab.configs => 'Search Config',
    _JobWorkbenchTab.profiles => 'Profiles Management',
    _JobWorkbenchTab.resumes => 'Resume Management',
    _JobWorkbenchTab.matches => 'Analysis Results',
    _JobWorkbenchTab.logs => 'Crawl Logs',
  };

  IconData get icon => switch (this) {
    _JobWorkbenchTab.jobsList => Icons.work_outline,
    _JobWorkbenchTab.configs => Icons.tune,
    _JobWorkbenchTab.profiles => Icons.person_search,
    _JobWorkbenchTab.resumes => Icons.description,
    _JobWorkbenchTab.matches => Icons.fact_check,
    _JobWorkbenchTab.logs => Icons.receipt_long,
  };
}

class _JobsContent extends StatelessWidget {
  const _JobsContent({
    required this.snapshot,
    required this.jobPage,
    required this.canRunCrawl,
    required this.canImportExportBackups,
    required this.selectedResumeId,
    required this.jobKeywordFilterController,
    required this.jobPageSizeController,
    required this.jobStatusFilter,
    required this.activeTab,
    required this.onTabChanged,
    required this.onJobStatusFilterChanged,
    required this.onApplyJobFilters,
    required this.onJobPageChanged,
    required this.onNewConfig,
    required this.onEditConfig,
    required this.onDeleteConfig,
    required this.onRequestCrawlAll,
    required this.onRequestCrawlConfig,
    required this.onRequestMatchAnalysis,
    required this.onShowJobDetails,
    required this.onUploadResume,
    required this.onCreateResume,
    required this.onViewResume,
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
  final bool canRunCrawl;
  final bool canImportExportBackups;
  final int? selectedResumeId;
  final TextEditingController jobKeywordFilterController;
  final TextEditingController jobPageSizeController;
  final String jobStatusFilter;
  final _JobWorkbenchTab activeTab;
  final ValueChanged<_JobWorkbenchTab> onTabChanged;
  final ValueChanged<String> onJobStatusFilterChanged;
  final Future<void> Function() onApplyJobFilters;
  final ValueChanged<int> onJobPageChanged;
  final VoidCallback onNewConfig;
  final ValueChanged<JobSearchConfig> onEditConfig;
  final ValueChanged<JobSearchConfig> onDeleteConfig;
  final Future<void> Function() onRequestCrawlAll;
  final ValueChanged<JobSearchConfig> onRequestCrawlConfig;
  final ValueChanged<JobItem> onRequestMatchAnalysis;
  final ValueChanged<JobItem> onShowJobDetails;
  final VoidCallback onUploadResume;
  final VoidCallback onCreateResume;
  final ValueChanged<ResumeItem> onViewResume;
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

  Widget _buildActiveTab(BuildContext context) => switch (activeTab) {
    _JobWorkbenchTab.jobsList => _buildJobsListTab(context),
    _JobWorkbenchTab.configs => _buildSearchConfigTab(context),
    _JobWorkbenchTab.profiles => _buildProfilesTab(context),
    _JobWorkbenchTab.resumes => _buildResumesTab(context),
    _JobWorkbenchTab.matches => _buildMatchesTab(context),
    _JobWorkbenchTab.logs => _buildLogsTab(context),
  };

  JobPageState _resolvedJobPageState() =>
      jobPage ??
      JobPageState(
        items: snapshot.jobs,
        page: 1,
        pageSize: int.tryParse(jobPageSizeController.text.trim()) ?? 20,
        total: snapshot.jobs.length,
      );

  Widget _buildJobsListTab(BuildContext context) {
    final pageState = _resolvedJobPageState();
    final jobs = pageState.items;

    return _WorkbenchPanel(
      title: 'Jobs List',
      trailing: TextButton.icon(
        key: const Key('job-crawl-all-button'),
        style: MavraButtonStyle.compactText(context: context),
        onPressed: canRunCrawl ? () => onRequestCrawlAll() : null,
        icon: const Icon(Icons.play_arrow, size: 18),
        label: const Text('Crawl All'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _JobFilters(
            keywordController: jobKeywordFilterController,
            pageSizeController: jobPageSizeController,
            statusFilter: jobStatusFilter,
            onStatusFilterChanged: onJobStatusFilterChanged,
            onApplyFilters: onApplyJobFilters,
          ),
          const SizedBox(height: 12),
          if (jobs.isEmpty)
            const Center(child: Text('No data'))
          else ...[
            _JobsTable(jobs: jobs, onShowDetails: onShowJobDetails),
            const SizedBox(height: 10),
            _JobPaginationControls(
              page: pageState,
              onPageChanged: onJobPageChanged,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchConfigTab(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WorkbenchPanel(
          title: 'Job Search Config',
          titleKey: const Key('job-config-panel-title'),
          dividerKey: const Key('job-config-panel-divider'),
          trailing: SizedBox(
            width: 160,
            child: FilledButton.icon(
              key: const Key('job-new-config-button'),
              style: MavraButtonStyle.compactFilled(context: context),
              onPressed: onNewConfig,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Config'),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot.configs.isEmpty)
                const Center(child: Text('No Configs'))
              else
                for (final config in snapshot.configs) ...[
                  _JobConfigCard(
                    config: config,
                    canRunCrawl: canRunCrawl,
                    onEdit: () => onEditConfig(config),
                    onDelete: () => onDeleteConfig(config),
                    onRequestCrawl: () => onRequestCrawlConfig(config),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfilesTab(BuildContext context) {
    return _WorkbenchPanel(
      title: 'Crawler Profiles',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton.icon(
            style: MavraButtonStyle.compactText(context: context),
            onPressed: canImportExportBackups ? onImportBackup : null,
            icon: const Icon(Icons.archive, size: 18),
            label: const Text('Import backup'),
          ),
          SizedBox(
            width: 172,
            child: FilledButton.icon(
              key: const Key('job-profile-create-button'),
              style: MavraButtonStyle.compactFilled(context: context),
              onPressed: onCreateProfile,
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Create profile'),
            ),
          ),
        ],
      ),
      child: snapshot.profiles.isEmpty
          ? const Center(child: Text('No profiles yet'))
          : _ProfilesTable(
              profiles: snapshot.profiles,
              onExportBackup: canImportExportBackups ? onExportBackup : null,
              onRenameProfile: onRenameProfile,
              onUpdateProfileStatus: onUpdateProfileStatus,
              onCopyProfile: onCopyProfile,
              onDeleteProfile: onDeleteProfile,
              onReleaseStaleProfile: canRunCrawl ? onReleaseStaleProfile : null,
              onOpenProfileLoginSession: canRunCrawl
                  ? onOpenProfileLoginSession
                  : null,
              onCloseProfileLoginSession: canRunCrawl
                  ? onCloseProfileLoginSession
                  : null,
              onTestProfile: canRunCrawl ? onTestProfile : null,
            ),
    );
  }

  Widget _buildResumesTab(BuildContext context) {
    return _WorkbenchPanel(
      title: 'Resume Management',
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          TextButton.icon(
            style: MavraButtonStyle.compactText(context: context),
            onPressed: onUploadResume,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Upload resume'),
          ),
          SizedBox(
            width: 172,
            child: FilledButton.icon(
              key: const Key('job-resume-create-button'),
              style: MavraButtonStyle.compactFilled(context: context),
              onPressed: onCreateResume,
              icon: const Icon(Icons.note_add, size: 18),
              label: const Text('Create resume'),
            ),
          ),
        ],
      ),
      child: snapshot.resumes.isEmpty
          ? const Center(child: Text('No resumes yet'))
          : Column(
              children: [
                for (final resume in snapshot.resumes)
                  Card(
                    key: Key('job-resume-card-${resume.id}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      dense: true,
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
                            style: MavraButtonStyle.rowIconButton(
                              context: context,
                            ),
                            onPressed: () => onSelectResume(resume),
                            icon: const Icon(
                              Icons.check_circle_outline,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            key: Key('job-resume-view-${resume.id}-button'),
                            tooltip: 'View ${resume.fileName}',
                            style: MavraButtonStyle.rowIconButton(
                              context: context,
                            ),
                            onPressed: () => onViewResume(resume),
                            icon: const Icon(
                              Icons.visibility_outlined,
                              size: 18,
                            ),
                          ),
                          IconButton(
                            key: Key('job-resume-edit-${resume.id}-button'),
                            tooltip: 'Edit ${resume.fileName}',
                            style: MavraButtonStyle.rowIconButton(
                              context: context,
                            ),
                            onPressed: () => onEditResume(resume),
                            icon: const Icon(Icons.edit, size: 18),
                          ),
                          IconButton(
                            key: Key('job-resume-delete-${resume.id}-button'),
                            tooltip: 'Delete ${resume.fileName}',
                            style: MavraButtonStyle.rowIconButton(
                              context: context,
                              isDangerous: true,
                            ),
                            onPressed: () => onDeleteResume(resume),
                            icon: const Icon(Icons.delete_outline, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildMatchesTab(BuildContext context) {
    return _WorkbenchPanel(
      title: 'Analysis Results',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MatchToolbar(
            resumes: snapshot.resumes,
            selectedResumeId: selectedResumeId,
          ),
          const SizedBox(height: 12),
          snapshot.matches.isEmpty
              ? const Center(child: Text('No Analysis Results'))
              : _MatchesTable(matches: snapshot.matches),
        ],
      ),
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    final configNames = {
      for (final config in snapshot.configs) config.id: config.name,
    };
    return _WorkbenchPanel(
      title: 'Recent Job Crawl Logs',
      child: snapshot.crawlLogs.isEmpty
          ? const Center(child: Text('No crawl logs yet'))
          : _CrawlLogsTable(logs: snapshot.crawlLogs, configNames: configNames),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MavraPageBanner(
            eyebrow: 'Job Search',
            title: 'Job Management',
            subtitle:
                'Configure Boss Zhipin, 51job, and Liepin search rules, intelligently match candidates',
          ),
          const SizedBox(height: 20),
          _JobTabStrip(activeTab: activeTab, onChanged: onTabChanged),
          const SizedBox(height: 16),
          _buildActiveTab(context),
        ],
      ),
    );
  }
}

class _WorkbenchPanel extends StatelessWidget {
  const _WorkbenchPanel({
    required this.title,
    required this.child,
    this.titleKey,
    this.dividerKey,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Key? titleKey;
  final Key? dividerKey;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return DecoratedBox(
          decoration: MavraTableStyle.panelDecoration(context),
          child: Padding(
            padding: EdgeInsets.all(wide ? 16 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final titleWidget = Text(
                      title,
                      key: titleKey,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: theme.textTheme.titleMedium,
                    );
                    final trailingWidget = trailing;
                    if (trailingWidget == null) {
                      return titleWidget;
                    }
                    if (constraints.maxWidth < 560) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          titleWidget,
                          const SizedBox(height: 8),
                          trailingWidget,
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: titleWidget),
                        const SizedBox(width: 12),
                        trailingWidget,
                      ],
                    );
                  },
                ),
                Divider(
                  key: dividerKey,
                  height: 24,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.7,
                  ),
                ),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JobConfigForm extends StatelessWidget {
  const _JobConfigForm({
    required this.nameController,
    required this.urlController,
    required this.profileKeyController,
    required this.keywordController,
    required this.locationController,
    required this.platformController,
    required this.cronController,
    required this.salaryMinController,
    required this.salaryMaxController,
    required this.experienceController,
    required this.educationController,
    required this.deactivationThresholdController,
  });

  final TextEditingController nameController;
  final TextEditingController urlController;
  final TextEditingController profileKeyController;
  final TextEditingController keywordController;
  final TextEditingController locationController;
  final TextEditingController platformController;
  final TextEditingController cronController;
  final TextEditingController salaryMinController;
  final TextEditingController salaryMaxController;
  final TextEditingController experienceController;
  final TextEditingController educationController;
  final TextEditingController deactivationThresholdController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          key: const Key('job-config-name-field'),
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Config Name'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-platform-field'),
          controller: platformController,
          decoration: const InputDecoration(labelText: 'Platform'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-profile-key-field'),
          controller: profileKeyController,
          decoration: const InputDecoration(labelText: 'Profile'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-url-field'),
          controller: urlController,
          decoration: const InputDecoration(labelText: 'Search URL'),
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
          decoration: const InputDecoration(labelText: 'City Code'),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('job-salary-min-field'),
                controller: salaryMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min Salary (K)'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                key: const Key('job-salary-max-field'),
                controller: salaryMaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max Salary (K)'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-experience-field'),
          controller: experienceController,
          decoration: const InputDecoration(labelText: 'Experience'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-education-field'),
          controller: educationController,
          decoration: const InputDecoration(labelText: 'Education'),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-deactivation-threshold-field'),
          controller: deactivationThresholdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Deactivation Threshold',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('job-cron-field'),
          controller: cronController,
          decoration: const InputDecoration(labelText: 'Cron'),
        ),
      ],
    );
  }
}

class _JobTabStrip extends StatelessWidget {
  const _JobTabStrip({required this.activeTab, required this.onChanged});

  final _JobWorkbenchTab activeTab;
  final ValueChanged<_JobWorkbenchTab> onChanged;

  static const _tabs = [
    _JobWorkbenchTab.jobsList,
    _JobWorkbenchTab.configs,
    _JobWorkbenchTab.profiles,
    _JobWorkbenchTab.resumes,
    _JobWorkbenchTab.matches,
    _JobWorkbenchTab.logs,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tab in _tabs)
          SizedBox(
            height: 40,
            child: ChoiceChip(
              key: Key(tab.key),
              avatar: Icon(tab.icon, size: 16),
              label: Text(tab.label),
              selected: activeTab == tab,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              showCheckmark: false,
              onSelected: (_) => onChanged(tab),
            ),
          ),
      ],
    );
  }
}

class _JobConfigCard extends StatelessWidget {
  const _JobConfigCard({
    required this.config,
    required this.canRunCrawl,
    required this.onEdit,
    required this.onDelete,
    required this.onRequestCrawl,
  });

  final JobSearchConfig config;
  final bool canRunCrawl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRequestCrawl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: Key('job-config-card-${config.id}'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(config.name, style: theme.textTheme.titleMedium),
                _PillText(config.platform),
                _PillText(config.active ? 'Enabled' : 'Disabled'),
                if (config.notifyOnNew) const _PillText('Notify'),
                _PillText(
                  config.enableMatchAnalysis
                      ? 'Auto-match on'
                      : 'Auto-match off',
                ),
                if (config.profileKey != null)
                  _PillText('Profile: ${config.profileKey}'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              config.url ?? '${config.keyword} - ${config.location}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 4),
            Text(
              '${config.keyword} - ${config.cityCode ?? config.location} - ${config.cron}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  key: Key('job-crawl-config-${config.id}-button'),
                  onPressed: canRunCrawl ? onRequestCrawl : null,
                  icon: const Icon(Icons.play_circle),
                  label: const Text('Crawl'),
                ),
                TextButton(
                  onPressed: onEdit,
                  child: Text('Edit ${config.name}'),
                ),
                TextButton.icon(
                  key: Key('job-delete-config-${config.id}-button'),
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillText extends StatelessWidget {
  const _PillText(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: theme.textTheme.labelSmall),
      ),
    );
  }
}

class _MatchToolbar extends StatelessWidget {
  const _MatchToolbar({required this.resumes, required this.selectedResumeId});

  final List<ResumeItem> resumes;
  final int? selectedResumeId;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 220,
          height: 40,
          child: DropdownButtonFormField<int?>(
            key: const Key('job-match-resume-filter'),
            initialValue: selectedResumeId,
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Select Resume',
            ),
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('Select Resume'),
              ),
              for (final resume in resumes)
                DropdownMenuItem<int?>(
                  value: resume.id,
                  child: Text(resume.fileName),
                ),
            ],
            onChanged: (_) {},
          ),
        ),
        SizedBox(
          width: 220,
          height: 40,
          child: DropdownButtonFormField<String>(
            key: const Key('job-match-recommendation-filter'),
            initialValue: 'all',
            isExpanded: true,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Recommendation',
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('Recommendation')),
              DropdownMenuItem(value: 'strong', child: Text('强烈推荐')),
              DropdownMenuItem(value: 'good', child: Text('推荐')),
              DropdownMenuItem(value: 'weak', child: Text('不推荐')),
            ],
            onChanged: (_) {},
          ),
        ),
        FilledButton.icon(
          key: const Key('job-reanalyze-button'),
          style: MavraButtonStyle.compactFilled(context: context),
          onPressed: resumes.isEmpty ? null : () {},
          icon: const Icon(Icons.psychology, size: 18),
          label: const Text('Re-analyze'),
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
          height: 40,
          child: TextField(
            key: const Key('job-keyword-filter'),
            controller: keywordController,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Keyword',
              suffixIcon: const Icon(Icons.search, size: 18),
            ),
          ),
        ),
        SizedBox(
          width: 120,
          height: 40,
          child: TextField(
            key: const Key('job-page-size-field'),
            controller: pageSizeController,
            keyboardType: TextInputType.number,
            decoration: MavraInputStyle.filterInput(
              context: context,
              label: 'Page size',
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: SegmentedButton<String>(
            key: const Key('job-status-filter'),
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'all', label: Text('All')),
              ButtonSegment(value: 'active', label: Text('Active')),
              ButtonSegment(value: 'inactive', label: Text('Inactive')),
            ],
            selected: {statusFilter},
            onSelectionChanged: (selection) =>
                onStatusFilterChanged(selection.first),
            style: MavraButtonStyle.filterSegmented(),
          ),
        ),
        SizedBox(
          width: 128,
          height: 40,
          child: MavraFilterButton.filled(
            key: const Key('job-apply-filters-button'),
            onPressed: onApplyFilters,
            icon: Icons.filter_alt,
            label: 'Apply',
          ),
        ),
      ],
    );
  }
}

class _JobPaginationControls extends StatelessWidget {
  const _JobPaginationControls({
    required this.page,
    required this.onPageChanged,
  });

  final JobPageState page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final totalPages = _totalPages(page.total, page.pageSize);
    final currentPage = page.page < 1 ? 1 : page.page;
    final canGoBack = currentPage > 1;
    final canGoForward = currentPage < totalPages;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Page $currentPage of $totalPages - ${page.total} jobs',
          key: const Key('job-pagination-summary'),
        ),
        const SizedBox(width: 8),
        IconButton(
          key: const Key('job-first-page-button'),
          tooltip: 'First page',
          onPressed: canGoBack ? () => onPageChanged(1) : null,
          icon: const Icon(Icons.first_page),
        ),
        IconButton(
          key: const Key('job-previous-page-button'),
          tooltip: 'Previous page',
          onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          key: const Key('job-next-page-button'),
          tooltip: 'Next page',
          onPressed: canGoForward ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        IconButton(
          key: const Key('job-last-page-button'),
          tooltip: 'Last page',
          onPressed: canGoForward ? () => onPageChanged(totalPages) : null,
          icon: const Icon(Icons.last_page),
        ),
      ],
    );
  }

  int _totalPages(int total, int pageSize) {
    if (total <= 0 || pageSize <= 0) {
      return 1;
    }
    final pages = (total + pageSize - 1) ~/ pageSize;
    return pages < 1 ? 1 : pages;
  }
}

class _IndexedJobRow {
  const _IndexedJobRow({required this.number, required this.job});

  final int number;
  final JobItem job;
}

class _JobsTable extends StatelessWidget {
  const _JobsTable({required this.jobs, required this.onShowDetails});

  final List<JobItem> jobs;
  final ValueChanged<JobItem> onShowDetails;

  @override
  Widget build(BuildContext context) {
    final rows = [
      for (var index = 0; index < jobs.length; index++)
        _IndexedJobRow(number: index + 1, job: jobs[index]),
    ];

    return MavraResponsiveDataView<_IndexedJobRow>(
      rows: rows,
      wideBreakpoint: 960,
      columnSpacing: 8,
      columns: const [
        DataColumn(label: _TableHeader('ID', width: 32)),
        DataColumn(label: _TableHeader('Platform', width: 56)),
        DataColumn(label: _TableHeader('Match', width: 72)),
        DataColumn(label: _TableHeader('Job Title', width: 180)),
        DataColumn(label: _TableHeader('Company', width: 180)),
        DataColumn(label: _TableHeader('Salary', width: 80)),
        DataColumn(label: _TableHeader('Location', width: 84)),
        DataColumn(label: _TableHeader('Status', width: 60)),
        DataColumn(label: _TableHeader('Last Updated', width: 88)),
        DataColumn(label: _TableHeader('Actions', width: 48)),
      ],
      tableCells: (row) {
        final job = row.job;
        return [
          DataCell(
            _TableTextCell(
              key: Key('job-id-cell-${job.id}'),
              text: '${row.number}',
              width: 32,
            ),
          ),
          DataCell(_TableTextCell(text: job.platform, width: 56)),
          DataCell(
            _TableTextCell(text: job.matchRecommendation ?? '-', width: 72),
          ),
          DataCell(_TableTextCell(text: job.title, width: 180)),
          DataCell(_TableTextCell(text: job.company, width: 180)),
          DataCell(_TableTextCell(text: job.salary ?? '-', width: 80)),
          DataCell(_TableTextCell(text: job.location, width: 84)),
          DataCell(_TableTextCell(text: job.status, width: 60)),
          DataCell(_TableTextCell(text: job.updatedAt ?? '-', width: 88)),
          DataCell(
            SizedBox(
              width: 48,
              child: IconButton(
                key: Key('job-detail-${job.id}-button'),
                tooltip: 'View ${job.title}',
                style: MavraButtonStyle.rowIconButton(context: context),
                onPressed: () => onShowDetails(job),
                icon: const Icon(Icons.open_in_new, size: 18),
              ),
            ),
          ),
        ];
      },
      mobileBuilder: (context, row) {
        final job = row.job;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.work),
            title: Text(job.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(job.company),
                Text(
                  '${job.salary ?? '-'} - ${job.location} - ${job.platform}',
                ),
                Text(job.matchRecommendation ?? '-'),
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
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader(this.label, {required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: Text(label));
  }
}

class _TableTextCell extends StatelessWidget {
  const _TableTextCell({super.key, required this.text, required this.width});

  final String text;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _JobDetailPanel extends StatelessWidget {
  const _JobDetailPanel({
    required this.detail,
    this.fallbackMessage,
    required this.onRequestMatchAnalysis,
  });

  final JobDetail detail;
  final String? fallbackMessage;
  final VoidCallback? onRequestMatchAnalysis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fallbackMessage != null) ...[
          Text(fallbackMessage!),
          const SizedBox(height: 12),
        ],
        Text(detail.company, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _DetailField(label: 'Job ID', value: '${detail.id}'),
            _DetailField(label: 'Salary', value: detail.salary ?? '-'),
            _DetailField(label: 'Location', value: detail.location ?? '-'),
            _DetailField(label: 'Experience', value: detail.experience ?? '-'),
            _DetailField(label: 'Education', value: detail.education ?? '-'),
            _DetailField(label: 'Status', value: detail.status ?? '-'),
            _DetailField(label: 'Last Updated', value: detail.updatedAt ?? '-'),
          ],
        ),
        if (detail.url != null) ...[
          const SizedBox(height: 12),
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

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(value, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _ProfilesTable extends StatelessWidget {
  const _ProfilesTable({
    required this.profiles,
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

  final List<CrawlProfileItem> profiles;
  final ValueChanged<String>? onExportBackup;
  final ValueChanged<CrawlProfileItem> onRenameProfile;
  final void Function(CrawlProfileItem profile, String status)
  onUpdateProfileStatus;
  final ValueChanged<CrawlProfileItem> onCopyProfile;
  final ValueChanged<CrawlProfileItem> onDeleteProfile;
  final ValueChanged<CrawlProfileItem>? onReleaseStaleProfile;
  final ValueChanged<CrawlProfileItem>? onOpenProfileLoginSession;
  final ValueChanged<CrawlProfileItem>? onCloseProfileLoginSession;
  final ValueChanged<CrawlProfileItem>? onTestProfile;

  void _handleMenuAction(CrawlProfileItem profile, String action) {
    switch (action) {
      case 'export':
        onExportBackup?.call(profile.profileKey);
        return;
      case 'rename':
        onRenameProfile(profile);
        return;
      case 'enable':
        onUpdateProfileStatus(profile, 'available');
        return;
      case 'copy':
        onCopyProfile(profile);
        return;
      case 'release':
        onReleaseStaleProfile?.call(profile);
        return;
      case 'open-login':
        onOpenProfileLoginSession?.call(profile);
        return;
      case 'close-login':
        onCloseProfileLoginSession?.call(profile);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('job-profiles-table'),
        columns: const [
          DataColumn(label: Text('Profile')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Platform')),
          DataColumn(label: Text('Task')),
          DataColumn(label: Text('Lease Until')),
          DataColumn(label: Text('Last Error')),
          DataColumn(label: Text('Actions')),
        ],
        rows: [
          for (final profile in profiles)
            DataRow(
              cells: [
                DataCell(Text(profile.profileKey)),
                DataCell(Text(profile.status)),
                DataCell(Text(profile.platform)),
                DataCell(Text(profile.taskId ?? '-')),
                DataCell(Text(profile.leaseUntil ?? '-')),
                DataCell(Text(profile.lastError ?? '-')),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        key: Key(
                          'job-profile-edit-menu-${profile.profileKey}-button',
                        ),
                        tooltip: 'Edit ${profile.profileKey}',
                        onSelected: (action) =>
                            _handleMenuAction(profile, action),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            key: Key(
                              'job-profile-export-${profile.profileKey}-button',
                            ),
                            value: 'export',
                            enabled: onExportBackup != null,
                            child: const Text('Export backup'),
                          ),
                          PopupMenuItem(
                            key: Key(
                              'job-profile-rename-${profile.profileKey}-button',
                            ),
                            value: 'rename',
                            child: const Text('Rename'),
                          ),
                          PopupMenuItem(
                            key: Key(
                              'job-profile-enable-${profile.profileKey}-button',
                            ),
                            value: 'enable',
                            child: const Text('Mark available'),
                          ),
                          PopupMenuItem(
                            key: Key(
                              'job-profile-copy-${profile.profileKey}-button',
                            ),
                            value: 'copy',
                            child: const Text('Copy'),
                          ),
                          PopupMenuItem(
                            key: Key(
                              'job-profile-release-${profile.profileKey}-button',
                            ),
                            value: 'release',
                            enabled: onReleaseStaleProfile != null,
                            child: const Text('Release stale'),
                          ),
                          PopupMenuItem(
                            key: Key(
                              'job-profile-login-${profile.profileKey}-button',
                            ),
                            value: 'open-login',
                            enabled: onOpenProfileLoginSession != null,
                            child: const Text('Open login'),
                          ),
                          PopupMenuItem(
                            key: Key(
                              'job-profile-close-login-${profile.profileKey}-button',
                            ),
                            value: 'close-login',
                            enabled: onCloseProfileLoginSession != null,
                            child: const Text('Close login'),
                          ),
                        ],
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          child: Text('Edit'),
                        ),
                      ),
                      TextButton(
                        key: Key(
                          'job-profile-test-${profile.profileKey}-button',
                        ),
                        onPressed: onTestProfile == null
                            ? null
                            : () => onTestProfile!(profile),
                        child: const Text('Test'),
                      ),
                      TextButton(
                        key: Key(
                          'job-profile-disable-${profile.profileKey}-button',
                        ),
                        onPressed: () =>
                            onUpdateProfileStatus(profile, 'disabled'),
                        child: const Text('Disable'),
                      ),
                      TextButton(
                        key: Key(
                          'job-profile-delete-${profile.profileKey}-button',
                        ),
                        onPressed: () => onDeleteProfile(profile),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MatchesTable extends StatelessWidget {
  const _MatchesTable({required this.matches});

  final List<JobMatchResult> matches;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('job-matches-table'),
        columns: const [
          DataColumn(label: Text('Recommendation')),
          DataColumn(label: Text('Job Title')),
          DataColumn(label: Text('Company')),
          DataColumn(label: Text('Salary')),
          DataColumn(label: Text('Reason')),
          DataColumn(label: Text('Analysis Time')),
          DataColumn(label: Text('Link')),
        ],
        rows: [
          for (final match in matches)
            DataRow(
              cells: [
                DataCell(Text(match.recommendation ?? match.score)),
                DataCell(Text(match.jobTitle)),
                DataCell(Text(match.company ?? '-')),
                DataCell(Text(match.salary ?? '-')),
                DataCell(Text(match.reason)),
                DataCell(Text(match.updatedAt ?? '-')),
                DataCell(Text(match.url == null ? '-' : 'View')),
              ],
            ),
        ],
      ),
    );
  }
}

class _CrawlLogsTable extends StatelessWidget {
  const _CrawlLogsTable({required this.logs, required this.configNames});

  final List<JobCrawlLog> logs;
  final Map<int, String> configNames;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        key: const Key('job-crawl-logs-table'),
        columns: const [
          DataColumn(label: Text('Time')),
          DataColumn(label: Text('Config')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('New Jobs')),
          DataColumn(label: Text('Total')),
          DataColumn(label: Text('Error')),
        ],
        rows: [
          for (final log in logs)
            DataRow(
              cells: [
                DataCell(Text(log.createdAt.toLocal().toString())),
                DataCell(
                  Text(
                    log.configId == null
                        ? '-'
                        : configNames[log.configId] ?? '#${log.configId}',
                  ),
                ),
                DataCell(Text(log.status)),
                DataCell(Text(log.newJobs?.toString() ?? '-')),
                DataCell(Text(log.totalJobs?.toString() ?? '-')),
                DataCell(Text(log.error ?? log.message)),
              ],
            ),
        ],
      ),
    );
  }
}

String? _emptyToNull(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
