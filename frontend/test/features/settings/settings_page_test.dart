import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/config/app_config.dart';
import 'package:mavra_frontend/core/platform/platform_capabilities.dart';
import 'package:mavra_frontend/features/settings/domain/settings_models.dart';
import 'package:mavra_frontend/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('renders config, API environment, and platform status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          repository: _FakeSettingsRepository.full(),
          config: const AppConfig(apiBaseUrl: 'https://api.example/api/v1'),
          capabilities: _windowsCapabilities(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('arfac'), findsOneWidget);
    expect(find.text('365'), findsOneWidget);
    expect(find.text('https://open.feishu.example/hook'), findsOneWidget);
    expect(find.text('API Environment'), findsOneWidget);
    expect(find.text('https://api.example/api/v1'), findsOneWidget);
    expect(find.text('File picker: available'), findsOneWidget);
    expect(find.text('Save dialog: available'), findsOneWidget);
    expect(find.text('Secure storage: windowsSecureStorage'), findsOneWidget);
  });

  testWidgets('validates and saves config updates', (tester) async {
    final repository = _FakeSettingsRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('settings-retention-field')),
      '0',
    );
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    expect(
      find.text('Retention must be between 1 and 3650 days'),
      findsOneWidget,
    );
    expect(repository.savedDrafts, isEmpty);

    await tester.enterText(
      find.byKey(const Key('settings-retention-field')),
      '30',
    );
    await tester.enterText(
      find.byKey(const Key('settings-feishu-field')),
      'https://open.feishu.example/new-hook',
    );
    await tester.tap(find.text('Save settings'));
    await tester.pumpAndSettle();

    expect(repository.savedDrafts.last.dataRetentionDays, 30);
    expect(
      repository.savedDrafts.last.feishuWebhookUrl,
      'https://open.feishu.example/new-hook',
    );
    expect(find.text('Saved settings'), findsOneWidget);
  });

  testWidgets('updates theme preference without backend writes', (
    tester,
  ) async {
    final repository = _FakeSettingsRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(find.text('Theme preference: dark'), findsOneWidget);
    expect(repository.savedDrafts, isEmpty);
  });

  testWidgets('renders loading, empty, error, and permission states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(repository: _SlowSettingsRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在加载设置...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(repository: _FakeSettingsRepository.empty()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('还没有可配置的偏好。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: SettingsPage(repository: _FailingSettingsRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('设置加载失败。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsPage(
          repository: _FakeSettingsRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('没有权限修改这些设置。'), findsOneWidget);
  });
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.snapshot);

  factory _FakeSettingsRepository.full() => _FakeSettingsRepository(
    SettingsSnapshot(
      userConfig: UserSettingsConfig(
        id: 1,
        username: 'arfac',
        dataRetentionDays: 365,
        feishuWebhookUrl: 'https://open.feishu.example/hook',
        updatedAt: DateTime.utc(2026, 6, 16),
      ),
      themeMode: 'system',
    ),
  );

  factory _FakeSettingsRepository.empty() =>
      _FakeSettingsRepository(const SettingsSnapshot.empty());

  final SettingsSnapshot snapshot;
  final savedDrafts = <SettingsDraft>[];

  @override
  Future<SettingsSnapshot> loadSettings() async => snapshot;

  @override
  Future<SettingsSnapshot> saveSettings(SettingsDraft draft) async {
    savedDrafts.add(draft);
    return SettingsSnapshot(
      userConfig: UserSettingsConfig(
        id: 1,
        username: 'arfac',
        dataRetentionDays: draft.dataRetentionDays,
        feishuWebhookUrl: draft.feishuWebhookUrl,
        updatedAt: DateTime.utc(2026, 6, 16),
      ),
      themeMode: draft.themeMode,
    );
  }
}

class _SlowSettingsRepository implements SettingsRepository {
  final _completer = Completer<SettingsSnapshot>();

  @override
  Future<SettingsSnapshot> loadSettings() => _completer.future;

  @override
  Future<SettingsSnapshot> saveSettings(SettingsDraft draft) async =>
      const SettingsSnapshot.empty();
}

class _FailingSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsSnapshot> loadSettings() {
    throw StateError('settings down');
  }

  @override
  Future<SettingsSnapshot> saveSettings(SettingsDraft draft) async =>
      const SettingsSnapshot.empty();
}

PlatformCapabilities _windowsCapabilities() {
  return PlatformCapabilities.forEnvironment(
    isWeb: false,
    platform: TargetPlatform.windows,
  );
}
