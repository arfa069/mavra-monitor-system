import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/widgets/mavra_responsive_data_view.dart';
import 'package:mavra_frontend/features/smart_home/domain/smart_home_models.dart';
import 'package:mavra_frontend/features/smart_home/presentation/smart_home_page.dart';

void main() {
  testWidgets('renders config, summary, entities, filters, and safe defaults', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('家里设备都在安静运行。'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.text('Home Assistant'), findsOneWidget);
    expect(find.text('https://ha.local'), findsOneWidget);
    expect(find.text('Unavailable devices 1'), findsOneWidget);
    expect(find.text('Living room lamp'), findsOneWidget);
    expect(find.text('light.living_room'), findsOneWidget);
    expect(find.text('on'), findsOneWidget);
    expect(find.text('Bedroom switch'), findsOneWidget);
    expect(find.text('switch.bedroom'), findsOneWidget);
    expect(repository.serviceCalls, isEmpty);

    await tester.tap(find.widgetWithText(ChoiceChip, 'light'));
    await tester.pumpAndSettle();

    expect(find.text('Living room lamp'), findsOneWidget);
    expect(find.text('Bedroom switch'), findsNothing);
  });

  testWidgets('edits Home Assistant config without exposing the token', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit config'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('smart-home-url-field')),
      'https://ha-new.local',
    );
    await tester.enterText(
      find.byKey(const Key('smart-home-token-field')),
      'new-secret-token',
    );
    await tester.ensureVisible(
      find.byKey(const Key('smart-home-test-config-button')),
    );
    await tester.tap(find.byKey(const Key('smart-home-test-config-button')));
    await tester.pumpAndSettle();

    expect(repository.testedConfig?.baseUrl, 'https://ha-new.local');
    expect(find.text('Home Assistant reachable'), findsOneWidget);

    await tester.tap(find.text('Save config'));
    await tester.pumpAndSettle();

    expect(repository.savedConfig?.baseUrl, 'https://ha-new.local');
    expect(repository.savedConfig?.token, 'new-secret-token');
    expect(find.text('new-secret-token'), findsNothing);
    expect(find.text('Saved Home Assistant config'), findsOneWidget);
  });

  testWidgets('submits mocked service calls and reports failures', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('service-entity-field')),
      'light.living_room',
    );
    await tester.enterText(
      find.byKey(const Key('service-name-field')),
      'turn_off',
    );
    await tester.tap(find.text('Call service'));
    await tester.pumpAndSettle();

    expect(repository.serviceCalls.single.entityId, 'light.living_room');
    expect(repository.serviceCalls.single.service, 'turn_off');
    expect(find.text('Service call queued'), findsOneWidget);

    await tester.ensureVisible(
      find.byKey(const Key('smart-home-entity-off-light.living_room')),
    );
    await tester.tap(
      find.byKey(const Key('smart-home-entity-off-light.living_room')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Call turn_off for light.living_room?'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('smart-home-confirm-light.living_room-turn_off')),
    );
    await tester.pumpAndSettle();

    expect(repository.serviceCalls.last.entityId, 'light.living_room');
    expect(repository.serviceCalls.last.service, 'turn_off');

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: _FailingServiceRepository())),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('service-entity-field')),
      'light.living_room',
    );
    await tester.enterText(
      find.byKey(const Key('service-name-field')),
      'turn_on',
    );
    await tester.tap(find.text('Call service'));
    await tester.pumpAndSettle();

    expect(find.text('Service call failed'), findsOneWidget);
  });

  testWidgets('matches React smart home entity table parity', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FakeSmartHomeRepository.full()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(MavraResponsiveDataView<SmartHomeEntityItem>),
      findsOneWidget,
    );
    expect(find.byType(DataTable), findsOneWidget);
    expect(
      find.byKey(const Key('smart-home-entity-row-light.living_room')),
      findsOneWidget,
    );
  });

  testWidgets('keeps entity state visible when control permission is denied', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FakeSmartHomeRepository.readOnly()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('没有权限控制这个设备。'), findsOneWidget);
    expect(find.text('Living room lamp'), findsOneWidget);
    expect(find.text('on'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Call service'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('renders loading, empty, error, and realtime update states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: _SlowSmartHomeRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('正在连接 Home Assistant...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FakeSmartHomeRepository.empty()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('还没有可控制的 Home Assistant 设备。'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FailingSmartHomeRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('智能家居状态加载失败。'), findsOneWidget);

    final realtime = _FakeSmartHomeRepository.full();
    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: realtime)),
    );
    await tester.pumpAndSettle();
    expect(find.text('on'), findsOneWidget);

    realtime.emitEntities([
      const SmartHomeEntityItem(
        domain: 'light',
        entityId: 'light.living_room',
        name: 'Living room lamp',
        state: 'off',
        area: 'Living room',
        available: true,
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('off'), findsOneWidget);
  });
}

class _FakeSmartHomeRepository implements SmartHomeRepository {
  _FakeSmartHomeRepository(this.snapshot);

  factory _FakeSmartHomeRepository.full() => _FakeSmartHomeRepository(
    const SmartHomeSnapshot(
      config: SmartHomeConfig(
        baseUrl: 'https://ha.local',
        enabled: true,
        lastStatus: 'ok',
        tokenConfigured: true,
      ),
      summary: SmartHomeSummary(
        configured: true,
        connected: true,
        activeCount: 2,
        unavailableCount: 1,
      ),
      entities: [
        SmartHomeEntityItem(
          domain: 'light',
          entityId: 'light.living_room',
          name: 'Living room lamp',
          state: 'on',
          area: 'Living room',
          available: true,
        ),
        SmartHomeEntityItem(
          domain: 'switch',
          entityId: 'switch.bedroom',
          name: 'Bedroom switch',
          state: 'off',
          area: 'Bedroom',
          available: false,
        ),
      ],
      canControl: true,
      canConfigure: true,
      realtimeConnected: true,
    ),
  );

  factory _FakeSmartHomeRepository.empty() => _FakeSmartHomeRepository(
    const SmartHomeSnapshot(
      config: null,
      summary: SmartHomeSummary(
        configured: false,
        connected: false,
        activeCount: 0,
        unavailableCount: 0,
      ),
      entities: [],
      canControl: true,
      canConfigure: true,
      realtimeConnected: false,
    ),
  );

  factory _FakeSmartHomeRepository.readOnly() => _FakeSmartHomeRepository(
    const SmartHomeSnapshot(
      config: SmartHomeConfig(
        baseUrl: 'https://ha.local',
        enabled: true,
        lastStatus: 'ok',
        tokenConfigured: true,
      ),
      summary: SmartHomeSummary(
        configured: true,
        connected: true,
        activeCount: 1,
        unavailableCount: 0,
      ),
      entities: [
        SmartHomeEntityItem(
          domain: 'light',
          entityId: 'light.living_room',
          name: 'Living room lamp',
          state: 'on',
          area: 'Living room',
          available: true,
        ),
      ],
      canControl: false,
      canConfigure: false,
      realtimeConnected: true,
    ),
  );

  final SmartHomeSnapshot snapshot;
  final savedConfigs = <SmartHomeConfigDraft>[];
  final testedConfigs = <SmartHomeConfigDraft>[];
  final serviceCalls = <SmartHomeServiceDraft>[];
  final _controller = StreamController<List<SmartHomeEntityItem>>.broadcast();

  SmartHomeConfigDraft? get savedConfig =>
      savedConfigs.isEmpty ? null : savedConfigs.last;

  SmartHomeConfigDraft? get testedConfig =>
      testedConfigs.isEmpty ? null : testedConfigs.last;

  @override
  Future<SmartHomeSnapshot> loadSmartHome() async => snapshot;

  @override
  Stream<List<SmartHomeEntityItem>> watchEntities() => _controller.stream;

  void emitEntities(List<SmartHomeEntityItem> entities) {
    _controller.add(entities);
  }

  @override
  Future<void> saveConfig(SmartHomeConfigDraft draft) async {
    savedConfigs.add(draft);
  }

  @override
  Future<SmartHomeServiceResult> testConfig(SmartHomeConfigDraft draft) async {
    testedConfigs.add(draft);
    return const SmartHomeServiceResult(
      ok: true,
      message: 'Home Assistant reachable',
    );
  }

  @override
  Future<SmartHomeServiceResult> callService(
    SmartHomeServiceDraft draft,
  ) async {
    serviceCalls.add(draft);
    return const SmartHomeServiceResult(
      ok: true,
      message: 'Service call queued',
    );
  }
}

class _SlowSmartHomeRepository implements SmartHomeRepository {
  final _completer = Completer<SmartHomeSnapshot>();

  @override
  Future<SmartHomeSnapshot> loadSmartHome() => _completer.future;

  @override
  Stream<List<SmartHomeEntityItem>> watchEntities() => const Stream.empty();

  @override
  Future<void> saveConfig(SmartHomeConfigDraft draft) async {}

  @override
  Future<SmartHomeServiceResult> testConfig(SmartHomeConfigDraft draft) async {
    return const SmartHomeServiceResult(ok: true, message: 'ok');
  }

  @override
  Future<SmartHomeServiceResult> callService(
    SmartHomeServiceDraft draft,
  ) async {
    return const SmartHomeServiceResult(ok: true, message: 'ok');
  }
}

class _FailingSmartHomeRepository implements SmartHomeRepository {
  @override
  Future<SmartHomeSnapshot> loadSmartHome() {
    throw StateError('smart home down');
  }

  @override
  Stream<List<SmartHomeEntityItem>> watchEntities() => const Stream.empty();

  @override
  Future<void> saveConfig(SmartHomeConfigDraft draft) async {}

  @override
  Future<SmartHomeServiceResult> testConfig(SmartHomeConfigDraft draft) async {
    return const SmartHomeServiceResult(ok: true, message: 'ok');
  }

  @override
  Future<SmartHomeServiceResult> callService(
    SmartHomeServiceDraft draft,
  ) async {
    return const SmartHomeServiceResult(ok: true, message: 'ok');
  }
}

class _FailingServiceRepository extends _FakeSmartHomeRepository {
  _FailingServiceRepository() : super(_FakeSmartHomeRepository.full().snapshot);

  @override
  Future<SmartHomeServiceResult> callService(SmartHomeServiceDraft draft) {
    throw StateError('service failed');
  }
}
