import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/files/file_service.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/jobs/domain/job_models.dart';
import 'package:mavra_frontend/features/jobs/presentation/jobs_page.dart';

void main() {
  testWidgets('renders the React-style default jobs workbench tab', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _FakeJobsRepository.full())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Job Management'), findsOneWidget);
    expect(find.text('Jobs List'), findsWidgets);
    expect(find.text('Search Config'), findsOneWidget);
    expect(find.text('Profiles Management'), findsOneWidget);
    expect(find.text('Resume Management'), findsOneWidget);
    expect(find.text('Analysis Results'), findsOneWidget);
    expect(find.text('Crawl Logs'), findsOneWidget);
    expect(find.byKey(const Key('job-tab-jobs-list')), findsOneWidget);
    expect(find.byKey(const Key('job-tab-configs')), findsOneWidget);
    expect(find.byKey(const Key('job-tab-profiles')), findsOneWidget);
    expect(find.byKey(const Key('job-tab-resumes')), findsOneWidget);
    expect(find.byKey(const Key('job-tab-matches')), findsOneWidget);
    expect(find.byKey(const Key('job-tab-logs')), findsOneWidget);
    expect(find.text('Job Search Config'), findsNothing);
    expect(find.text('Senior Flutter Engineer'), findsOneWidget);
    expect(find.text('Mavra Labs'), findsOneWidget);
    expect(find.text('Boss Zhipin'), findsNothing);
    expect(find.textContaining('0 8 * * *'), findsNothing);
    expect(find.text('resume.pdf'), findsNothing);
    expect(find.text('92%'), findsNothing);
    expect(find.text('boss-main'), findsNothing);
    expect(find.text('Job crawl completed'), findsNothing);

    await tester.tap(find.byKey(const Key('job-tab-configs')));
    await tester.pumpAndSettle();

    expect(find.text('Job Search Config'), findsOneWidget);
    expect(find.byKey(const Key('job-config-card-7')), findsOneWidget);
    expect(find.text('Jobs List'), findsOneWidget);
    expect(find.text('Boss Zhipin'), findsOneWidget);
    expect(find.textContaining('0 8 * * *'), findsOneWidget);
    expect(find.text('Senior Flutter Engineer'), findsNothing);
    expect(find.byKey(const Key('job-keyword-filter')), findsNothing);
  });

  testWidgets(
    'exposes safe crawl, match, resume, and profile management intents',
    (tester) async {
      final repository = _FakeJobsRepository.full();
      tester.view.physicalSize = const Size(2200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(home: JobsPage(repository: repository)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('job-crawl-all-button')));
      await tester.tap(find.byKey(const Key('job-crawl-all-button')));
      await tester.pumpAndSettle();
      expect(repository.crawlAllRequested, isTrue);
      expect(find.text('Job crawl requested'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('job-tab-configs')));
      await tester.tap(find.byKey(const Key('job-tab-configs')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('job-crawl-config-7-button')),
      );
      await tester.tap(find.byKey(const Key('job-crawl-config-7-button')));
      await tester.pumpAndSettle();
      expect(repository.crawledConfigId, 7);

      await tester.ensureVisible(find.byKey(const Key('job-tab-jobs-list')));
      await tester.tap(find.byKey(const Key('job-tab-jobs-list')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('job-detail-1-button')));
      await tester.tap(find.byKey(const Key('job-detail-1-button')));
      await tester.pumpAndSettle();
      expect(find.text('Job details: Senior Flutter Engineer'), findsOneWidget);
      await tester.tap(find.byKey(const Key('job-match-1-button')));
      await tester.pumpAndSettle();
      expect(repository.matchedJobId, 1);
      expect(repository.matchedResumeId, 3);

      await tester.ensureVisible(find.byKey(const Key('job-tab-resumes')));
      await tester.tap(find.byKey(const Key('job-tab-resumes')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('job-resume-delete-3-button')),
      );
      await tester.tap(find.byKey(const Key('job-resume-delete-3-button')));
      await tester.pumpAndSettle();
      expect(repository.deletedResumeId, 3);

      await tester.ensureVisible(find.byKey(const Key('job-tab-profiles')));
      await tester.tap(find.byKey(const Key('job-tab-profiles')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
      );
      await tester.tap(
        find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('job-profile-copy-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.copiedProfileKey, 'boss-main');

      await tester.tap(
        find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('job-profile-release-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.releasedProfileKey, 'boss-main');

      await tester.tap(
        find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('job-profile-login-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.openedLoginProfileKey, 'boss-main');

      await tester.tap(
        find.byKey(const Key('job-profile-test-boss-main-button')),
      );
      await tester.pumpAndSettle();
      expect(repository.testedProfileKey, 'boss-main');
    },
  );

  testWidgets('matches React jobs workbench parity interactions', (
    tester,
  ) async {
    final repository = _FakeJobsRepository.full();
    tester.view.physicalSize = const Size(2200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('job-keyword-filter')), findsOneWidget);
    expect(find.byKey(const Key('job-status-filter')), findsOneWidget);
    expect(find.byKey(const Key('job-page-size-field')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('job-apply-filters-button'))).width,
      lessThan(220),
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('job-status-filter'))).dy,
      tester.getTopLeft(find.byKey(const Key('job-page-size-field'))).dy,
    );
    expect(
      tester.getBottomLeft(find.byKey(const Key('job-status-filter'))).dy,
      tester.getBottomLeft(find.byKey(const Key('job-page-size-field'))).dy,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('job-apply-filters-button'))).dy,
      tester.getTopLeft(find.byKey(const Key('job-page-size-field'))).dy,
    );
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('job-apply-filters-button')))
          .dy,
      tester.getBottomLeft(find.byKey(const Key('job-page-size-field'))).dy,
    );
    expect(
      find.byWidgetPredicate((widget) => widget is MavraResponsiveDataView),
      findsOneWidget,
    );
    expect(find.byType(DataTable), findsOneWidget);

    await tester.enterText(find.byKey(const Key('job-keyword-filter')), 'ai');
    await tester.enterText(find.byKey(const Key('job-page-size-field')), '10');
    await tester.tap(find.text('Inactive'));
    await tester.tap(find.byKey(const Key('job-apply-filters-button')));
    await tester.pumpAndSettle();

    expect(repository.lastListQuery.keyword, 'ai');
    expect(repository.lastListQuery.status, 'inactive');
    expect(repository.lastListQuery.pageSize, 10);

    await tester.tap(find.byKey(const Key('job-detail-1-button')));
    await tester.pumpAndSettle();

    expect(repository.loadedJobDetailId, 1);
    expect(find.byKey(const Key('mavra-side-sheet-panel')), findsOneWidget);
    expect(find.text('Fake job detail'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-resumes')));
    await tester.tap(find.byKey(const Key('job-tab-resumes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('job-resume-create-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-resume-name-field')),
      'frontend resume',
    );
    await tester.enterText(
      find.byKey(const Key('job-resume-text-field')),
      'Flutter, Windows, API integration',
    );
    await tester.tap(find.byKey(const Key('job-resume-save-button')));
    await tester.pumpAndSettle();

    expect(repository.createdResumeDraft?.name, 'frontend resume');

    await tester.tap(find.byKey(const Key('job-resume-edit-3-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-resume-name-field')),
      'resume revised',
    );
    expect(
      tester.getSize(find.byKey(const Key('job-resume-text-field'))).height,
      greaterThan(260),
    );
    await tester.tap(find.byKey(const Key('job-resume-save-button')));
    await tester.pumpAndSettle();

    expect(repository.updatedResumeId, 3);
    expect(repository.updatedResumeDraft?.name, 'resume revised');

    await tester.tap(find.byKey(const Key('job-resume-select-3-button')));
    await tester.pumpAndSettle();

    expect(repository.selectedResumeId, 3);
  });

  testWidgets('matches React modal and table layout for each jobs tab', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeJobsRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-configs')));
    await tester.tap(find.byKey(const Key('job-tab-configs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-config-panel-title')), findsOneWidget);
    expect(find.byKey(const Key('job-config-panel-divider')), findsOneWidget);

    await tester.tap(find.text('Edit Boss Zhipin'));
    await tester.pumpAndSettle();
    expect(find.text('Edit Job Config'), findsOneWidget);
    expect(find.byKey(const Key('job-url-field')), findsOneWidget);
    expect(
      find.text('https://www.zhipin.com/web/geek/job?query=flutter'),
      findsWidgets,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-profiles')));
    await tester.tap(find.byKey(const Key('job-tab-profiles')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-profiles-table')), findsOneWidget);
    expect(
      find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
      findsOneWidget,
    );
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Last Error'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('job-tab-resumes')));
    await tester.tap(find.byKey(const Key('job-tab-resumes')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('job-resume-edit-3-button')));
    await tester.pumpAndSettle();
    expect(find.text('Edit: resume.pdf'), findsOneWidget);
    expect(find.byKey(const Key('job-resume-text-field')), findsOneWidget);
    expect(find.text('Existing Flutter resume content'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-matches')));
    await tester.tap(find.byKey(const Key('job-tab-matches')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-matches-table')), findsOneWidget);
    expect(find.text('Recommendation'), findsWidgets);
    expect(find.text('Company'), findsOneWidget);
    expect(find.text('Reason'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('job-tab-logs')));
    await tester.tap(find.byKey(const Key('job-tab-logs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-crawl-logs-table')), findsOneWidget);
    expect(find.text('Time'), findsOneWidget);
    expect(find.text('Config'), findsOneWidget);
    expect(find.text('New Jobs'), findsOneWidget);
  });

  testWidgets('matches React jobs tab controls and card behaviors', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _FakeJobsRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-configs')));
    await tester.tap(find.byKey(const Key('job-tab-configs')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-config-card-7')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('job-config-card-7'))).width,
      greaterThan(1000),
    );
    expect(find.text('Profile: boss-main'), findsOneWidget);
    expect(
      find.text('https://www.zhipin.com/web/geek/job?query=flutter'),
      findsOneWidget,
    );
    expect(find.text('Enabled'), findsOneWidget);
    expect(find.text('Notify'), findsOneWidget);
    expect(find.text('Auto-match off'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('job-new-config-button'))).width,
      lessThan(220),
    );

    await tester.ensureVisible(find.byKey(const Key('job-tab-jobs-list')));
    await tester.tap(find.byKey(const Key('job-tab-jobs-list')));
    await tester.pumpAndSettle();
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Platform'), findsOneWidget);
    expect(find.text('Match'), findsOneWidget);
    expect(find.text('Job Title'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    expect(find.text('Last Updated'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('job-id-cell-1')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('wPuNz5SYTcPiS'), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('job-id-cell-2')),
        matching: find.text('2'),
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('job-id-cell-1'))).width,
      lessThanOrEqualTo(180),
    );
    expect(find.byKey(const Key('job-pagination-summary')), findsOneWidget);
    expect(find.text('Page 1 of 3 - 42 jobs'), findsOneWidget);
    final nextPage = tester.widget<IconButton>(
      find.byKey(const Key('job-next-page-button')),
    );
    expect(nextPage.onPressed, isNotNull);
    await tester.tap(find.byKey(const Key('job-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastListQuery.page, 2);
    final previousPage = tester.widget<IconButton>(
      find.byKey(const Key('job-previous-page-button')),
    );
    expect(previousPage.onPressed, isNotNull);
    expect(
      tester.getSize(find.byKey(const Key('job-apply-filters-button'))).width,
      lessThan(220),
    );

    await tester.ensureVisible(find.byKey(const Key('job-tab-profiles')));
    await tester.tap(find.byKey(const Key('job-tab-profiles')));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.text('Disable'), findsOneWidget);
    expect(find.text('Open login'), findsNothing);
    expect(find.text('Release stale'), findsNothing);
    await tester.tap(
      find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Open login'), findsOneWidget);
    expect(find.text('Release stale'), findsOneWidget);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-resumes')));
    await tester.tap(find.byKey(const Key('job-tab-resumes')));
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const Key('job-resume-create-button'))).width,
      lessThan(220),
    );
    expect(find.byKey(const Key('job-resume-card-3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('job-resume-view-3-button')));
    await tester.pumpAndSettle();
    expect(find.text('View: resume.pdf'), findsOneWidget);
    expect(find.text('Existing Flutter resume content'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-matches')));
    await tester.tap(find.byKey(const Key('job-tab-matches')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('job-match-resume-filter')), findsOneWidget);
    expect(
      find.byKey(const Key('job-match-recommendation-filter')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('job-reanalyze-button')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('job-tab-logs')));
    await tester.tap(find.byKey(const Key('job-tab-logs')));
    await tester.pumpAndSettle();
    expect(find.text('Boss Zhipin'), findsOneWidget);
  });

  testWidgets('detail fallback does not leave a failed status on tab changes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: JobsPage(repository: _DetailFailingJobsRepository.full()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-detail-1-button')));
    await tester.tap(find.byKey(const Key('job-detail-1-button')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Detail failed:'), findsNothing);
    expect(find.text('Showing list data because full details are unavailable.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-profiles')));
    await tester.tap(find.byKey(const Key('job-tab-profiles')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Detail failed:'), findsNothing);
  });

  testWidgets('falls back to row details when job detail loading fails', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository =
        _DetailFailingJobsRepository(_FakeJobsRepository.full().snapshot);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-detail-1-button')));
    await tester.tap(find.byKey(const Key('job-detail-1-button')));
    await tester.pumpAndSettle();

    expect(find.text('Job details: Senior Flutter Engineer'), findsOneWidget);
    expect(find.textContaining('Detail failed:'), findsNothing);
    expect(find.text('Showing list data because full details are unavailable.'), findsOneWidget);
  });

  testWidgets('creates and edits a job search config from the form', (
    tester,
  ) async {
    final repository = _FakeJobsRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-configs')));
    await tester.tap(find.byKey(const Key('job-tab-configs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add Config'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('job-config-name-field')),
      'Liepin data',
    );
    await tester.enterText(
      find.byKey(const Key('job-keyword-field')),
      'data engineer',
    );
    await tester.enterText(
      find.byKey(const Key('job-location-field')),
      'Shenzhen',
    );
    await tester.enterText(
      find.byKey(const Key('job-platform-field')),
      'liepin',
    );
    await tester.enterText(
      find.byKey(const Key('job-cron-field')),
      '0 10 * * *',
    );
    await tester.ensureVisible(find.text('Save config'));
    await tester.tap(find.text('Save config'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.last.keyword, 'data engineer');
    expect(repository.savedDrafts.last.platform, 'liepin');

    await tester.ensureVisible(find.text('Edit Boss Zhipin'));
    await tester.tap(find.text('Edit Boss Zhipin'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('job-keyword-field')));
    await tester.enterText(
      find.byKey(const Key('job-keyword-field')),
      'flutter lead',
    );
    await tester.ensureVisible(find.text('Save config'));
    await tester.tap(find.text('Save config'));
    await tester.pumpAndSettle();

    expect(repository.updatedConfigId, 7);
    expect(repository.savedDrafts.last.keyword, 'flutter lead');
  });

  testWidgets('uploads resumes and imports/exports profile backups', (
    tester,
  ) async {
    final repository = _FakeJobsRepository.full();
    final fileService = _FakeFileService();

    await tester.pumpWidget(
      MaterialApp(
        home: JobsPage(repository: repository, fileService: fileService),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('job-tab-resumes')));
    await tester.tap(find.byKey(const Key('job-tab-resumes')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Upload resume'));
    await tester.pumpAndSettle();
    expect(repository.uploadedResumeName, 'resume-new.pdf');
    expect(find.text('Uploaded resume-new.pdf'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('job-tab-profiles')));
    await tester.tap(find.byKey(const Key('job-tab-profiles')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    expect(repository.importedBackupName, 'profiles.zip');
    expect(find.text('Imported profiles.zip'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
    );
    await tester.tap(
      find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('job-profile-export-boss-main-button')),
    );
    await tester.pumpAndSettle();
    expect(repository.exportedProfileKey, 'boss-main');
    expect(fileService.savedName, 'boss-main.zip');
  });

  testWidgets('renders loading, empty, and error states', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _SlowJobsRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _FakeJobsRepository.empty())),
    );
    await tester.pumpAndSettle();
    expect(find.text('No data'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: JobsPage(repository: _FailingJobsRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Jobs unavailable'), findsOneWidget);
  });

  testWidgets(
    'disables dangerous crawl and profile actions without permission',
    (tester) async {
      tester.view.physicalSize = const Size(2200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: JobsPage(
            repository: _FakeJobsRepository.full(),
            permissions: const {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final crawlAll = tester.widget<TextButton>(
        find.byKey(const Key('job-crawl-all-button')),
      );
      expect(crawlAll.onPressed, isNull);

      await tester.ensureVisible(find.byKey(const Key('job-tab-profiles')));
      await tester.tap(find.byKey(const Key('job-tab-profiles')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('job-profile-edit-menu-boss-main-button')),
      );
      await tester.pumpAndSettle();
      final profileLogin = tester.widget<PopupMenuItem<Object?>>(
        find.byKey(const Key('job-profile-login-boss-main-button')),
      );
      expect(profileLogin.enabled, isFalse);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('job-tab-jobs-list')));
      await tester.tap(find.byKey(const Key('job-tab-jobs-list')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('job-detail-1-button')));
      await tester.tap(find.byKey(const Key('job-detail-1-button')));
      await tester.pumpAndSettle();

      final match = tester.widget<FilledButton>(
        find.byKey(const Key('job-match-1-button')),
      );
      expect(match.onPressed, isNull);
    },
  );
}

class _FakeJobsRepository implements JobsRepository {
  _FakeJobsRepository(this.snapshot);

  factory _FakeJobsRepository.full() => _FakeJobsRepository(
    JobsSnapshot(
      jobs: const [
        JobItem(
          id: 1,
          title: 'Senior Flutter Engineer',
          company: 'Mavra Labs',
          platform: 'boss',
          location: 'Shanghai',
          status: 'new',
          jobId:
              'wPuNz5SYTcPiS-T1fbi6s7vfL_U_xRkO_X5iEY7JsD0YptalcUK3JzVRJ6IXXmdsveiTDkdBIgo9uKjkU2ZY75',
          salary: '30-45K',
          updatedAt: '2026-06-16 09:00',
          url: 'https://jobs.example/1',
          matchRecommendation: '强烈推荐',
        ),
        JobItem(
          id: 2,
          title: 'Support Engineer',
          company: 'Mavra Support',
          platform: '51job',
          location: 'Guangzhou',
          status: 'active',
          jobId: '172490542',
          salary: '10-15K',
          updatedAt: '2026-06-16 10:00',
          url: 'https://jobs.example/2',
          matchRecommendation: '可以考虑',
        ),
      ],
      page: JobPageState(
        items: [
          JobItem(
            id: 1,
            title: 'Senior Flutter Engineer',
            company: 'Mavra Labs',
            platform: 'boss',
            location: 'Shanghai',
            status: 'new',
            jobId:
                'wPuNz5SYTcPiS-T1fbi6s7vfL_U_xRkO_X5iEY7JsD0YptalcUK3JzVRJ6IXXmdsveiTDkdBIgo9uKjkU2ZY75',
            salary: '30-45K',
            updatedAt: '2026-06-16 09:00',
            url: 'https://jobs.example/1',
            matchRecommendation: '强烈推荐',
          ),
          JobItem(
            id: 2,
            title: 'Support Engineer',
            company: 'Mavra Support',
            platform: '51job',
            location: 'Guangzhou',
            status: 'active',
            jobId: '172490542',
            salary: '10-15K',
            updatedAt: '2026-06-16 10:00',
            url: 'https://jobs.example/2',
            matchRecommendation: '可以考虑',
          ),
        ],
        page: 1,
        pageSize: 20,
        total: 42,
      ),
      configs: const [
        JobSearchConfig(
          id: 7,
          name: 'Boss Zhipin',
          platform: 'boss',
          keyword: 'flutter',
          location: 'Shanghai',
          cron: '0 8 * * *',
          url: 'https://www.zhipin.com/web/geek/job?query=flutter',
          profileKey: 'boss-main',
          cityCode: '101020100',
          salaryMin: 20,
          salaryMax: 40,
          experience: '3-5 years',
          education: 'Bachelor',
          active: true,
          notifyOnNew: true,
          enableMatchAnalysis: false,
          deactivationThreshold: 3,
        ),
      ],
      resumes: [
        ResumeItem(
          id: 3,
          fileName: 'resume.pdf',
          resumeText: 'Existing Flutter resume content',
          updatedAt: DateTime.utc(2026, 6, 16, 9),
        ),
      ],
      matches: const [
        JobMatchResult(
          jobTitle: 'Senior Flutter Engineer',
          company: 'Mavra Labs',
          salary: '30-45K',
          score: '92%',
          recommendation: '强烈推荐',
          reason: 'Strong Flutter and Windows desktop fit',
          updatedAt: '2026-06-16 09:00',
        ),
      ],
      profiles: const [
        CrawlProfileItem(
          platform: 'boss',
          profileKey: 'boss-main',
          status: 'ready',
          taskId: 'task-1',
          leaseUntil: '2026-06-16 10:00',
          lastError: '-',
        ),
      ],
      crawlLogs: [
        JobCrawlLog(
          message: 'Job crawl completed',
          status: 'success',
          createdAt: DateTime.utc(2026, 6, 16, 8),
          configId: 7,
          newJobs: 2,
          totalJobs: 12,
        ),
      ],
    ),
  );

  factory _FakeJobsRepository.empty() => _FakeJobsRepository(
    const JobsSnapshot(
      jobs: [],
      configs: [],
      resumes: [],
      matches: [],
      profiles: [],
      crawlLogs: [],
    ),
  );

  final JobsSnapshot snapshot;
  final savedDrafts = <JobConfigDraft>[];
  int? updatedConfigId;
  String? uploadedResumeName;
  String? importedBackupName;
  String? exportedProfileKey;
  bool crawlAllRequested = false;
  int? crawledConfigId;
  int? deletedConfigId;
  int? loadedJobDetailId;
  int? matchedJobId;
  int? matchedResumeId;
  int? deletedResumeId;
  String? createdProfileKey;
  String? updatedProfileKey;
  String? renamedProfileKey;
  String? copiedProfileKey;
  String? deletedProfileKey;
  String? releasedProfileKey;
  String? openedLoginProfileKey;
  String? closedLoginProfileKey;
  String? testedProfileKey;
  JobListQuery lastListQuery = const JobListQuery();
  ResumeDraft? createdResumeDraft;
  int? updatedResumeId;
  ResumeDraft? updatedResumeDraft;
  int? selectedResumeId;

  @override
  Future<JobsSnapshot> loadJobs() async => snapshot;

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    lastListQuery = query;
    return JobPageState(
      items: snapshot.jobs,
      page: query.page,
      pageSize: query.pageSize,
      total: snapshot.page.total == 0
          ? snapshot.jobs.length
          : snapshot.page.total,
    );
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    loadedJobDetailId = jobId;
    final job = snapshot.jobs.firstWhere((item) => item.id == jobId);
    return JobDetail(
      id: job.id,
      title: job.title,
      company: job.company,
      description: 'Fake job detail',
      url: 'https://jobs.example/$jobId',
      salary: job.salary,
      location: job.location,
      status: job.status,
      updatedAt: job.updatedAt,
    );
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async {
    return snapshot.matches;
  }

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {
    savedDrafts.add(draft);
    updatedConfigId = configId;
  }

  @override
  Future<void> uploadResume(PickedFileReference file) async {
    uploadedResumeName = file.name;
  }

  @override
  Future<void> createResume(ResumeDraft draft) async {
    createdResumeDraft = draft;
  }

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {
    updatedResumeId = resumeId;
    updatedResumeDraft = draft;
  }

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {
    importedBackupName = file.name;
  }

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    exportedProfileKey = profileKey;
    return ProfileBackupExport(fileName: '$profileKey.zip', bytes: const [9]);
  }

  @override
  Future<void> deleteConfig(int configId) async {
    deletedConfigId = configId;
  }

  @override
  Future<void> requestCrawlAll() async {
    crawlAllRequested = true;
  }

  @override
  Future<void> requestCrawlConfig(int configId) async {
    crawledConfigId = configId;
  }

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {
    matchedJobId = jobId;
    matchedResumeId = resumeId;
  }

  @override
  Future<void> deleteResume(int resumeId) async {
    deletedResumeId = resumeId;
  }

  @override
  Future<void> selectResumeForMatch(int resumeId) async {
    selectedResumeId = resumeId;
  }

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {
    createdProfileKey = profileKey;
  }

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {
    updatedProfileKey = profileKey;
  }

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {
    renamedProfileKey = newProfileKey;
  }

  @override
  Future<void> copyProfile(String profileKey) async {
    copiedProfileKey = profileKey;
  }

  @override
  Future<void> deleteProfile(String profileKey) async {
    deletedProfileKey = profileKey;
  }

  @override
  Future<void> releaseStaleProfile(String profileKey) async {
    releasedProfileKey = profileKey;
  }

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {
    openedLoginProfileKey = profileKey;
  }

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {
    closedLoginProfileKey = profileKey;
  }

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {
    testedProfileKey = profileKey;
  }
}

class _SlowJobsRepository implements JobsRepository {
  final _completer = Completer<JobsSnapshot>();

  @override
  Future<JobsSnapshot> loadJobs() => _completer.future;

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    return JobPageState(
      items: const [],
      page: query.page,
      pageSize: query.pageSize,
      total: 0,
    );
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> createResume(ResumeDraft draft) async {}

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return const ProfileBackupExport(fileName: 'backup.zip', bytes: []);
  }

  @override
  Future<void> deleteConfig(int configId) async {}

  @override
  Future<void> requestCrawlAll() async {}

  @override
  Future<void> requestCrawlConfig(int configId) async {}

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {}

  @override
  Future<void> deleteResume(int resumeId) async {}

  @override
  Future<void> selectResumeForMatch(int resumeId) async {}

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {}

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {}

  @override
  Future<void> copyProfile(String profileKey) async {}

  @override
  Future<void> deleteProfile(String profileKey) async {}

  @override
  Future<void> releaseStaleProfile(String profileKey) async {}

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {}

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {}
}

class _FailingJobsRepository implements JobsRepository {
  @override
  Future<JobsSnapshot> loadJobs() {
    throw StateError('jobs down');
  }

  @override
  Future<JobPageState> listJobs(JobListQuery query) async {
    throw StateError('jobs down');
  }

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    throw StateError('jobs down');
  }

  @override
  Future<List<JobMatchResult>> listMatchResults({
    int? resumeId,
    int? jobId,
    int page = 1,
    int pageSize = 20,
  }) async => const [];

  @override
  Future<void> saveConfig(JobConfigDraft draft, {int? configId}) async {}

  @override
  Future<void> uploadResume(PickedFileReference file) async {}

  @override
  Future<void> createResume(ResumeDraft draft) async {}

  @override
  Future<void> updateResume(int resumeId, ResumeDraft draft) async {}

  @override
  Future<void> importProfileBackup(PickedFileReference file) async {}

  @override
  Future<ProfileBackupExport> exportProfileBackup(String profileKey) async {
    return const ProfileBackupExport(fileName: 'backup.zip', bytes: []);
  }

  @override
  Future<void> deleteConfig(int configId) async {}

  @override
  Future<void> requestCrawlAll() async {}

  @override
  Future<void> requestCrawlConfig(int configId) async {}

  @override
  Future<void> requestMatchAnalysis(int jobId, {required int resumeId}) async {}

  @override
  Future<void> deleteResume(int resumeId) async {}

  @override
  Future<void> selectResumeForMatch(int resumeId) async {}

  @override
  Future<void> createProfile({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> updateProfileStatus({
    required String profileKey,
    required String status,
  }) async {}

  @override
  Future<void> renameProfile({
    required String profileKey,
    required String newProfileKey,
  }) async {}

  @override
  Future<void> copyProfile(String profileKey) async {}

  @override
  Future<void> deleteProfile(String profileKey) async {}

  @override
  Future<void> releaseStaleProfile(String profileKey) async {}

  @override
  Future<void> openProfileLoginSession({
    required String profileKey,
    required String platform,
  }) async {}

  @override
  Future<void> closeProfileLoginSession(String profileKey) async {}

  @override
  Future<void> testProfile({
    required String profileKey,
    required String platform,
  }) async {}
}

class _FakeFileService extends FileService {
  _FakeFileService()
    : super(canPickFiles: true, canSaveFiles: true, canDownloadFiles: true);

  int _pickCount = 0;
  String? savedName;

  @override
  Future<PickedFileReference?> pickFile() async {
    _pickCount += 1;
    if (_pickCount == 1) {
      return const PickedFileReference(name: 'resume-new.pdf', bytes: [1]);
    }
    return const PickedFileReference(name: 'profiles.zip', bytes: [2]);
  }

  @override
  Future<void> saveBytes({
    required String suggestedName,
    required List<int> bytes,
  }) async {
    savedName = suggestedName;
  }
}

class _DetailFailingJobsRepository extends _FakeJobsRepository {
  _DetailFailingJobsRepository(super.snapshot);

  factory _DetailFailingJobsRepository.full() =>
      _DetailFailingJobsRepository(_FakeJobsRepository.full().snapshot);

  @override
  Future<JobDetail> loadJobDetail(int jobId) async {
    throw StateError('detail unavailable');
  }
}
