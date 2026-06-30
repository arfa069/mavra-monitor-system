import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/core/notifications/mavra_notifier.dart';
import 'package:mavra_frontend/features/smart_home/domain/smart_home_models.dart';
import 'package:mavra_frontend/features/smart_home/presentation/smart_home_page.dart';
import 'package:mavra_frontend/visual_qa/visual_qa_app.dart';

void main() {
  testWidgets('renders the React parity header and grouped entity cards', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: MavraNotifier.scaffoldMessengerKey,
        home: SmartHomePage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart Home'), findsWidgets);
    expect(find.text('Home Assistant devices and scenes'), findsOneWidget);
    expect(find.text('Connected'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Refresh'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Configure'), findsOneWidget);
    expect(find.text('Living room'), findsOneWidget);
    expect(find.text('Garage'), findsOneWidget);
    expect(find.text('Evening scene'), findsWidgets);
    expect(
      find.byKey(const Key('smart-home-card-light.living_room')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('smart-home-card-cover.garage')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('smart-home-card-climate.hallway')),
      findsOneWidget,
    );
    expect(find.text('Service request'), findsNothing);
    expect(find.text('Config form'), findsNothing);
    expect(find.byType(DataTable), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
  });

  testWidgets('keeps the React parity shell layout horizontal on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildVisualQaApp(initialLocation: '/smart-home'));
    await tester.pumpAndSettle();

    final titleBox = tester.renderObject<RenderBox>(
      find.text('Smart Home').last,
    );
    expect(titleBox.size.width, greaterThan(140));
    expect(titleBox.size.height, lessThan(48));

    final refreshBox = tester.renderObject<RenderBox>(
      find.widgetWithText(OutlinedButton, 'Refresh'),
    );
    expect(refreshBox.size.width, greaterThan(72));
    expect(refreshBox.size.height, lessThan(56));
    final bannerBottom = tester
        .getBottomLeft(find.byKey(const Key('smart-home-title-banner')))
        .dy;
    final bannerSize = tester.getSize(
      find.byKey(const Key('smart-home-title-banner')),
    );
    final refreshTop = tester
        .getTopLeft(find.byKey(const Key('smart-home-refresh-button')))
        .dy;
    expect(bannerSize.width, greaterThan(900));
    expect(refreshTop, greaterThan(bannerBottom));

    final cardBox = tester.renderObject<RenderBox>(
      find.byKey(const Key('smart-home-card-light.living_room')),
    );
    expect(cardBox.size.width, greaterThan(180));
  });

  testWidgets('opens Configure as a modal and saves without exposing token', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: MavraNotifier.scaffoldMessengerKey,
        home: SmartHomePage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Configure'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byKey(const Key('smart-home-config-dialog')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('smart-home-url-field')),
      'https://ha-new.local',
    );
    await tester.enterText(
      find.byKey(const Key('smart-home-token-field')),
      'new-secret-token',
    );
    await tester.tap(find.byKey(const Key('smart-home-test-config-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.testedConfig?.baseUrl, 'https://ha-new.local');
    expect(find.text('Home Assistant reachable'), findsOneWidget);

    await tester.tap(find.byKey(const Key('smart-home-save-config-button')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(repository.savedConfig?.baseUrl, 'https://ha-new.local');
    expect(repository.savedConfig?.token, 'new-secret-token');
    expect(find.text('new-secret-token'), findsNothing);
    expect(find.text('Smart home config saved'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('controls React entity widgets with the correct services', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('smart-home-toggle-light.living_room')),
    );
    await tester.pumpAndSettle();
    expect(repository.serviceCalls.last.entityId, 'light.living_room');
    expect(repository.serviceCalls.last.service, 'turn_off');

    await tester.tap(
      find.byKey(const Key('smart-home-cover-open-cover.garage')),
    );
    await tester.tap(
      find.byKey(const Key('smart-home-cover-stop-cover.garage')),
    );
    await tester.tap(
      find.byKey(const Key('smart-home-cover-close-cover.garage')),
    );
    await tester.pumpAndSettle();
    expect(
      repository.serviceCalls.map((call) => call.service).toList(),
      containsAllInOrder(['open_cover', 'stop_cover', 'close_cover']),
    );

    await tester.tap(
      find.byKey(const Key('smart-home-climate-mode-climate.hallway')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('heat').last);
    await tester.pumpAndSettle();
    expect(repository.serviceCalls.last.entityId, 'climate.hallway');
    expect(repository.serviceCalls.last.service, 'set_hvac_mode');
    expect(repository.serviceCalls.last.serviceData, {'hvac_mode': 'heat'});

    await tester.enterText(
      find.byKey(const Key('smart-home-temperature-climate.hallway')),
      '22',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(repository.serviceCalls.last.service, 'set_temperature');
    expect(repository.serviceCalls.last.serviceData, {'temperature': 22.0});

    await tester.tap(find.byKey(const Key('smart-home-run-scene.evening')));
    await tester.pumpAndSettle();
    expect(find.text('Run Evening scene?'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('smart-home-confirm-scene.evening-turn_on')),
    );
    await tester.pumpAndSettle();
    expect(repository.serviceCalls.last.entityId, 'scene.evening');
    expect(repository.serviceCalls.last.service, 'turn_on');
  });

  testWidgets('groups auxiliary switches with their parent climate device', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(
          repository: _FakeSmartHomeRepository.deviceGrouped(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final airConditionerGroup = find.text('空调').first;
    expect(airConditionerGroup, findsOneWidget);

    final groupTop = tester.getTopLeft(airConditionerGroup).dy;
    final climateTop = tester
        .getTopLeft(
          find.byKey(
            const Key(
              'smart-home-card-climate.wiing_ym01_ffd1_air_conditioner',
            ),
          ),
        )
        .dy;
    final swingTop = tester
        .getTopLeft(
          find.byKey(
            const Key('smart-home-card-switch.wiing_ym01_ffd1_vertical_swing'),
          ),
        )
        .dy;
    final sleepTop = tester
        .getTopLeft(
          find.byKey(
            const Key('smart-home-card-switch.wiing_ym01_ffd1_sleep_mode'),
          ),
        )
        .dy;

    expect(climateTop, greaterThan(groupTop));
    expect(swingTop, greaterThan(groupTop));
    expect(sleepTop, greaterThan(groupTop));
    expect(swingTop - climateTop, lessThan(260));
    expect(sleepTop - climateTop, lessThan(260));
  });

  testWidgets('updates switch state optimistically after a service call', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.deviceGrouped();
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    var toggle = tester.widget<Switch>(
      find.byKey(const Key('smart-home-toggle-switch.zhimi_fa1_alarm')),
    );
    expect(toggle.value, isTrue);

    final alarmToggle = find.byKey(
      const Key('smart-home-toggle-switch.zhimi_fa1_alarm'),
    );
    await tester.ensureVisible(alarmToggle);
    await tester.tap(alarmToggle);
    await tester.pumpAndSettle();

    expect(repository.serviceCalls.last.entityId, 'switch.zhimi_fa1_alarm');
    expect(repository.serviceCalls.last.service, 'turn_off');
    expect(find.text('off'), findsOneWidget);

    toggle = tester.widget<Switch>(
      find.byKey(const Key('smart-home-toggle-switch.zhimi_fa1_alarm')),
    );
    expect(toggle.value, isFalse);
  });

  testWidgets('keeps entity state unchanged when a service call is rejected', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.deviceGrouped()
      ..serviceResult = const SmartHomeServiceResult(
        ok: false,
        message: 'Home Assistant rejected the command',
      );

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: MavraNotifier.scaffoldMessengerKey,
        home: SmartHomePage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final alarmToggle = find.byKey(
      const Key('smart-home-toggle-switch.zhimi_fa1_alarm'),
    );
    await tester.ensureVisible(alarmToggle);
    await tester.tap(alarmToggle);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final toggle = tester.widget<Switch>(alarmToggle);
    expect(toggle.value, isTrue);
    expect(find.text('Home Assistant rejected the command'), findsOneWidget);
  });

  testWidgets('disables controls for unavailable entities', (tester) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: repository)),
    );
    await tester.pumpAndSettle();

    final bedroomToggle = tester.widget<Switch>(
      find.byKey(const Key('smart-home-toggle-switch.bedroom')),
    );
    expect(bedroomToggle.onChanged, isNull);

    final unavailableRepository = _FakeSmartHomeRepository(
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
          activeCount: 0,
          unavailableCount: 2,
        ),
        entities: [
          SmartHomeEntityItem(
            domain: 'cover',
            entityId: 'cover.offline',
            name: 'Offline cover',
            state: 'unavailable',
            area: 'Garage',
            available: false,
          ),
          SmartHomeEntityItem(
            domain: 'scene',
            entityId: 'scene.offline',
            name: 'Offline scene',
            state: 'unavailable',
            area: null,
            available: false,
          ),
        ],
        canControl: true,
        canConfigure: true,
        realtimeConnected: true,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: unavailableRepository)),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('smart-home-cover-open-cover.offline')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('smart-home-run-scene.offline')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('hides Configure and disables controls without permission', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FakeSmartHomeRepository.readOnly()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Configure'), findsNothing);
    expect(find.text('Living room lamp'), findsOneWidget);
    expect(find.text('on'), findsOneWidget);

    final toggle = tester.widget<Switch>(
      find.byKey(const Key('smart-home-toggle-light.living_room')),
    );
    expect(toggle.onChanged, isNull);

    final runButton = tester.widget<FilledButton>(
      find.byKey(const Key('smart-home-run-scene.evening')),
    );
    expect(runButton.onPressed, isNull);
  });

  testWidgets('renders loading, empty, error, and realtime update states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: _SlowSmartHomeRepository())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Connecting to Home Assistant...'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FakeSmartHomeRepository.empty()),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('No supported Home Assistant entities found'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(repository: _FailingSmartHomeRepository()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Failed to load smart home entities'), findsOneWidget);
    expect(find.text('Smart Home'), findsWidgets);

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

  testWidgets('ignores stale smart home loads after a newer refresh wins', (
    tester,
  ) async {
    final staleRepository = _SequencedSmartHomeRepository([
      Completer<SmartHomeSnapshot>(),
    ]);
    final latestRepository = _SequencedSmartHomeRepository([
      Completer<SmartHomeSnapshot>(),
    ]);

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: staleRepository)),
    );
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(home: SmartHomePage(repository: latestRepository)),
    );
    await tester.pump();

    latestRepository.complete(
      0,
      const SmartHomeSnapshot(
        config: null,
        summary: SmartHomeSummary(
          configured: true,
          connected: true,
          activeCount: 1,
          unavailableCount: 0,
        ),
        entities: [
          SmartHomeEntityItem(
            domain: 'light',
            entityId: 'light.latest',
            name: 'Latest load',
            state: 'on',
            area: 'Lab',
            available: true,
          ),
        ],
        canControl: true,
        canConfigure: true,
        realtimeConnected: true,
      ),
    );
    await tester.pumpAndSettle();

    staleRepository.complete(
      0,
      const SmartHomeSnapshot(
        config: null,
        summary: SmartHomeSummary(
          configured: true,
          connected: true,
          activeCount: 1,
          unavailableCount: 0,
        ),
        entities: [
          SmartHomeEntityItem(
            domain: 'light',
            entityId: 'light.stale',
            name: 'Stale load',
            state: 'on',
            area: 'Lab',
            available: true,
          ),
        ],
        canControl: true,
        canConfigure: true,
        realtimeConnected: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest load'), findsOneWidget);
    expect(find.text('Stale load'), findsNothing);
  });

  testWidgets('reports realtime entity stream errors without crashing', (
    tester,
  ) async {
    final repository = _FakeSmartHomeRepository.full();

    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: MavraNotifier.scaffoldMessengerKey,
        home: SmartHomePage(repository: repository),
      ),
    );
    await tester.pumpAndSettle();

    repository.emitEntityError(StateError('stream down'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Smart home updates interrupted'), findsOneWidget);
  });

  testWidgets('explicit permissions override repository permission flags', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SmartHomePage(
          repository: _FakeSmartHomeRepository.full(),
          permissions: const {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Configure'), findsNothing);
    final toggle = tester.widget<Switch>(
      find.byKey(const Key('smart-home-toggle-light.living_room')),
    );
    expect(toggle.onChanged, isNull);
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
        activeCount: 6,
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
        SmartHomeEntityItem(
          domain: 'cover',
          entityId: 'cover.garage',
          name: 'Garage door',
          state: 'closed',
          area: 'Garage',
          available: true,
        ),
        SmartHomeEntityItem(
          domain: 'climate',
          entityId: 'climate.hallway',
          name: 'Hallway thermostat',
          state: 'cool',
          area: 'Hallway',
          available: true,
          attributes: {
            'hvac_modes': ['cool', 'heat', 'off'],
            'temperature': 21.0,
            'min_temp': 16.0,
            'max_temp': 30.0,
          },
        ),
        SmartHomeEntityItem(
          domain: 'scene',
          entityId: 'scene.evening',
          name: 'Evening scene',
          state: 'idle',
          area: null,
          available: true,
        ),
        SmartHomeEntityItem(
          domain: 'script',
          entityId: 'script.movie',
          name: 'Movie mode',
          state: 'idle',
          area: null,
          available: true,
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

  factory _FakeSmartHomeRepository.deviceGrouped() => _FakeSmartHomeRepository(
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
        activeCount: 4,
        unavailableCount: 0,
      ),
      entities: [
        SmartHomeEntityItem(
          domain: 'switch',
          entityId: 'switch.wiing_ym01_ffd1_vertical_swing',
          name: '上下摆风',
          state: 'unavailable',
          area: null,
          available: false,
        ),
        SmartHomeEntityItem(
          domain: 'switch',
          entityId: 'switch.wiing_ym01_ffd1_sleep_mode',
          name: '睡眠模式',
          state: 'unavailable',
          area: null,
          available: false,
        ),
        SmartHomeEntityItem(
          domain: 'climate',
          entityId: 'climate.wiing_ym01_ffd1_air_conditioner',
          name: '空调',
          state: 'cool',
          area: null,
          available: true,
          attributes: {
            'hvac_modes': ['cool', 'heat', 'off'],
            'temperature': 24.0,
          },
        ),
        SmartHomeEntityItem(
          domain: 'switch',
          entityId: 'switch.zhimi_fa1_alarm',
          name: '风扇 提示音',
          state: 'on',
          area: null,
          available: true,
        ),
        SmartHomeEntityItem(
          domain: 'fan',
          entityId: 'fan.zhimi_fa1_fan',
          name: '风扇',
          state: 'on',
          area: null,
          available: true,
        ),
      ],
      canControl: true,
      canConfigure: true,
      realtimeConnected: true,
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
        activeCount: 6,
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
          domain: 'scene',
          entityId: 'scene.evening',
          name: 'Evening scene',
          state: 'idle',
          area: null,
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
  SmartHomeServiceResult serviceResult = const SmartHomeServiceResult(
    ok: true,
    message: 'Service call queued',
  );

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

  void emitEntityError(Object error) {
    _controller.addError(error);
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
    return serviceResult;
  }
}

class _SequencedSmartHomeRepository implements SmartHomeRepository {
  _SequencedSmartHomeRepository(this._completers);

  final List<Completer<SmartHomeSnapshot>> _completers;
  final _controller = StreamController<List<SmartHomeEntityItem>>.broadcast();
  var _loadCount = 0;

  @override
  Future<SmartHomeSnapshot> loadSmartHome() {
    final completer = _completers[_loadCount];
    _loadCount += 1;
    return completer.future;
  }

  void complete(int index, SmartHomeSnapshot snapshot) {
    _completers[index].complete(snapshot);
  }

  @override
  Stream<List<SmartHomeEntityItem>> watchEntities() => _controller.stream;

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
