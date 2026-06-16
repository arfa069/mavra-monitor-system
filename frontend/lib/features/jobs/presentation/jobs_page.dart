import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/files/file_service.dart';
import '../../../core/platform/platform_capabilities.dart';
import '../../../core/widgets/adaptive_scaffold.dart';
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
  Object? _error;
  String? _statusMessage;
  int? _editingConfigId;
  bool _showConfigForm = false;

  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  final _locationController = TextEditingController();
  final _platformController = TextEditingController();
  final _cronController = TextEditingController();

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
                  statusMessage: _statusMessage,
                  showConfigForm: _showConfigForm,
                  nameController: _nameController,
                  keywordController: _keywordController,
                  locationController: _locationController,
                  platformController: _platformController,
                  cronController: _cronController,
                  onNewConfig: _newConfig,
                  onSaveConfig: _saveConfig,
                  onEditConfig: _editConfig,
                  onUploadResume: _uploadResume,
                  onImportBackup: _importBackup,
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
    required this.statusMessage,
    required this.showConfigForm,
    required this.nameController,
    required this.keywordController,
    required this.locationController,
    required this.platformController,
    required this.cronController,
    required this.onNewConfig,
    required this.onSaveConfig,
    required this.onEditConfig,
    required this.onUploadResume,
    required this.onImportBackup,
    required this.onExportBackup,
  });

  final JobsSnapshot snapshot;
  final String? statusMessage;
  final bool showConfigForm;
  final TextEditingController nameController;
  final TextEditingController keywordController;
  final TextEditingController locationController;
  final TextEditingController platformController;
  final TextEditingController cronController;
  final VoidCallback onNewConfig;
  final Future<void> Function() onSaveConfig;
  final ValueChanged<JobSearchConfig> onEditConfig;
  final VoidCallback onUploadResume;
  final VoidCallback onImportBackup;
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
              FilledButton.icon(
                onPressed: onNewConfig,
                icon: const Icon(Icons.add),
                label: const Text('New config'),
              ),
            ],
          ),
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
          if (snapshot.jobs.isEmpty)
            const Center(child: Text('No jobs yet'))
          else
            for (final job in snapshot.jobs) _JobTile(job: job),
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
                  trailing: TextButton(
                    onPressed: () => onEditConfig(config),
                    child: Text('Edit ${config.name}'),
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
              for (final resume in snapshot.resumes)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.description),
                  title: Text(resume.fileName),
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
              for (final profile in snapshot.profiles)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_search),
                  title: Text(profile.profileKey),
                  subtitle: Text('${profile.platform} - ${profile.status}'),
                  trailing: TextButton(
                    onPressed: () => onExportBackup(profile.profileKey),
                    child: Text('Export backup ${profile.profileKey}'),
                  ),
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

class _JobTile extends StatelessWidget {
  const _JobTile({required this.job});

  final JobItem job;

  @override
  Widget build(BuildContext context) {
    return Card(
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
        trailing: Text(job.status),
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
