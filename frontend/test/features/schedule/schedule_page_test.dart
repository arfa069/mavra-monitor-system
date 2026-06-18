import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/features/schedule/domain/schedule_models.dart';
import 'package:mavra_frontend/features/schedule/presentation/schedule_page.dart';

void main() {
  testWidgets(
    'renders product schedules, job schedules, and scheduler status',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SchedulePage(repository: _FakeScheduleRepository.full()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Rules'), findsOneWidget);
      expect(find.text('Scheduler running'), findsOneWidget);
      expect(find.text('Asia/Shanghai'), findsOneWidget);
      expect(find.text('Product schedules'), findsOneWidget);
      expect(find.byKey(const Key('schedule-product-table')), findsOneWidget);
      expect(find.text('taobao'), findsOneWidget);
      expect(find.text('0 9 * * *'), findsOneWidget);
      expect(find.text('Next run 2026-06-17 09:00'), findsOneWidget);
      expect(find.text('Job schedules'), findsOneWidget);
      expect(find.byKey(const Key('schedule-job-table')), findsOneWidget);
      expect(find.text('Boss morning'), findsOneWidget);
      expect(find.text('30 8 * * 1-5'), findsOneWidget);
    },
  );

  testWidgets('saves retention and webhook configuration', (tester) async {
    final repository = _FakeScheduleRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SchedulePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification and retention'), findsOneWidget);
    expect(find.text('365 days'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('schedule-retention-days-field')),
      '180',
    );
    await tester.enterText(
      find.byKey(const Key('schedule-webhook-url-field')),
      'https://open.feishu.cn/webhook/test',
    );
    await tester.tap(find.byKey(const Key('schedule-save-settings-button')));
    await tester.pumpAndSettle();

    expect(repository.savedSettings?.retentionDays, 180);
    expect(
      repository.savedSettings?.feishuWebhookUrl,
      'https://open.feishu.cn/webhook/test',
    );
    expect(find.text('Saved schedule settings'), findsOneWidget);
  });

  testWidgets('previews cron and saves a rule draft', (tester) async {
    final repository = _FakeScheduleRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SchedulePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New rule'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-target-field')),
      'jd',
    );
    await tester.enterText(find.byKey(const Key('schedule-hour-field')), '9');
    await tester.enterText(find.byKey(const Key('schedule-minute-field')), '0');
    await tester.enterText(
      find.byKey(const Key('schedule-weekdays-field')),
      '1-5',
    );
    await tester.tap(find.text('预览 cron'));
    await tester.pumpAndSettle();

    expect(repository.previewedDraft?.targetName, 'jd');
    expect(find.text('0 9 * * 1-5'), findsWidgets);

    await tester.tap(find.text('保存规则'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.single.targetName, 'jd');
    expect(repository.savedDrafts.single.cronExpression, '0 9 * * 1-5');
    expect(find.text('Saved jd'), findsOneWidget);
  });

  testWidgets('validates cron inputs before preview or save', (tester) async {
    final repository = _FakeScheduleRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SchedulePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New rule'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('schedule-target-field')),
      'jd',
    );
    await tester.enterText(find.byKey(const Key('schedule-hour-field')), '25');
    await tester.enterText(find.byKey(const Key('schedule-minute-field')), '0');
    await tester.tap(find.text('预览 cron'));
    await tester.pumpAndSettle();

    expect(find.text('Hour must be 0-23'), findsOneWidget);
    expect(repository.previewedDraft, isNull);

    await tester.tap(find.text('保存规则'));
    await tester.pumpAndSettle();
    expect(repository.savedDrafts, isEmpty);
  });

  testWidgets('renders loading, empty, error, and read-only states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SchedulePage(repository: _SlowScheduleRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载自动规则...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SchedulePage(repository: _FakeScheduleRepository.empty()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('还没有自动运行规则。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: SchedulePage(repository: _FailingScheduleRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('规则加载失败。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SchedulePage(repository: _FakeScheduleRepository.readOnly()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有权限修改自动规则。'), findsOneWidget);
    final newRule = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'New rule'),
    );
    expect(newRule.onPressed, isNull);
  });
}

class _FakeScheduleRepository implements ScheduleRepository {
  _FakeScheduleRepository(this.snapshot);

  factory _FakeScheduleRepository.full() => _FakeScheduleRepository(
    ScheduleSnapshot(
      status: const SchedulerStatus(
        label: 'Scheduler running',
        timezone: 'Asia/Shanghai',
      ),
      productSchedules: const [
        ProductSchedule(
          platform: 'taobao',
          cronExpression: '0 9 * * *',
          nextRunAt: '2026-06-17 09:00',
        ),
      ],
      jobSchedules: const [
        JobSchedule(
          configId: 7,
          name: 'Boss morning',
          cronExpression: '30 8 * * 1-5',
          nextRunAt: '2026-06-17 08:30',
        ),
      ],
      settings: const ScheduleSettings(
        retentionDays: 365,
        feishuWebhookUrl: 'https://open.feishu.cn/webhook/current',
      ),
      canConfigure: true,
    ),
  );

  factory _FakeScheduleRepository.empty() => _FakeScheduleRepository(
    const ScheduleSnapshot(
      status: SchedulerStatus(label: 'Scheduler stopped', timezone: null),
      productSchedules: [],
      jobSchedules: [],
      settings: ScheduleSettings.defaults,
      canConfigure: true,
    ),
  );

  factory _FakeScheduleRepository.readOnly() => _FakeScheduleRepository(
    ScheduleSnapshot(
      status: const SchedulerStatus(
        label: 'Scheduler running',
        timezone: 'Asia/Shanghai',
      ),
      productSchedules: const [
        ProductSchedule(
          platform: 'taobao',
          cronExpression: '0 9 * * *',
          nextRunAt: null,
        ),
      ],
      jobSchedules: const [],
      settings: const ScheduleSettings(retentionDays: 365),
      canConfigure: false,
    ),
  );

  final ScheduleSnapshot snapshot;
  final savedDrafts = <ScheduleRuleDraft>[];
  ScheduleSettings? savedSettings;
  ScheduleRuleDraft? previewedDraft;

  @override
  Future<ScheduleSnapshot> loadSchedule() async => snapshot;

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    previewedDraft = draft;
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {
    savedDrafts.add(draft);
  }

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {
    savedSettings = settings;
  }
}

class _SlowScheduleRepository implements ScheduleRepository {
  final _completer = Completer<ScheduleSnapshot>();

  @override
  Future<ScheduleSnapshot> loadSchedule() => _completer.future;

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {}

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {}
}

class _FailingScheduleRepository implements ScheduleRepository {
  @override
  Future<ScheduleSnapshot> loadSchedule() {
    throw StateError('scheduler down');
  }

  @override
  Future<CronPreview> previewCron(ScheduleRuleDraft draft) async {
    return CronPreview(expression: draft.cronExpression);
  }

  @override
  Future<void> saveRule(ScheduleRuleDraft draft) async {}

  @override
  Future<void> saveSettings(ScheduleSettings settings) async {}
}
