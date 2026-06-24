import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/features/events/domain/event_models.dart';
import 'package:mavra_frontend/features/events/presentation/events_page.dart';

void main() {
  testWidgets('renders React parity banner, filters, and table only once', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeEventRepository(items: [_fullEvent()]);

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('events-desktop-layout')), findsOneWidget);
    expect(find.byKey(const Key('events-banner')), findsOneWidget);
    expect(find.text('System Events'), findsOneWidget);
    expect(find.text('Event Center'), findsOneWidget);
    expect(
      find.text(
        'Unified audit, runtime, and platform event stream with realtime updates',
      ),
      findsOneWidget,
    );

    expect(find.text('Today'), findsNothing);
    expect(find.text('Alerts'), findsNothing);
    expect(find.text('Analytics'), findsNothing);

    final bannerBottom = tester
        .getBottomLeft(find.byKey(const Key('events-banner')))
        .dy;
    final toolbarTop = tester
        .getTopLeft(find.byKey(const Key('events-filter-toolbar')))
        .dy;
    expect(toolbarTop, greaterThan(bannerBottom));
    expect(find.byKey(const Key('events-apply-filters-button')), findsNothing);
    expect(
      find.byKey(const Key('events-reset-filters-button')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const Key('events-reset-filters-button'))).dy,
      tester.getTopLeft(find.byKey(const Key('events-end-field'))).dy,
    );
    expect(
      tester
          .getBottomLeft(find.byKey(const Key('events-reset-filters-button')))
          .dy,
      tester.getBottomLeft(find.byKey(const Key('events-end-field'))).dy,
    );

    for (final label in const [
      'Kind',
      'Event Type',
      'Message',
      'Severity',
      'Source',
      'Time',
      'Action',
    ]) {
      expect(find.text(label), findsAtLeastNWidgets(1));
    }
    expect(find.text('USER.LOGIN'), findsNothing);
    expect(find.text('user.login'), findsWidgets);
    expect(find.text('AUDIT'), findsOneWidget);
    expect(find.text('INFO'), findsOneWidget);
    expect(find.text('Total 1 events'), findsOneWidget);
    expect(find.text('Page 1 of 1'), findsOneWidget);
  });

  testWidgets('applies filters, page size, pagination, and reset', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeEventRepository(
      items: [
        _fullEvent(),
        _fullEvent(
          id: 'evt-2',
          kind: EventKind.platform,
          eventType: 'profile.challenge',
          category: 'crawler',
          severity: 'warning',
          source: 'api',
          message: 'Boss profile requires review',
        ),
      ],
      total: 60,
    );

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('events-kind-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Platform').last);
    await tester.pumpAndSettle();
    expect(repository.lastQuery.filter, EventFilter.platform);
    expect(repository.lastQuery.page, 1);

    await tester.enterText(
      find.byKey(const Key('events-type-field')),
      'profile.challenge',
    );
    await tester.enterText(
      find.byKey(const Key('events-category-field')),
      'crawler',
    );
    await tester.tap(find.byKey(const Key('events-severity-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Warning').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('events-source-field')), 'api');
    await tester.enterText(
      find.byKey(const Key('events-keyword-field')),
      'profile',
    );
    await tester.enterText(
      find.byKey(const Key('events-start-field')),
      '2026-06-01T00:00:00Z',
    );
    await tester.enterText(
      find.byKey(const Key('events-end-field')),
      '2026-06-18T00:00:00Z',
    );
    await tester.pumpAndSettle();

    expect(repository.lastQuery.eventType, 'profile.challenge');
    expect(repository.lastQuery.category, 'crawler');
    expect(repository.lastQuery.severity, 'warning');
    expect(repository.lastQuery.source, 'api');
    expect(repository.lastQuery.keyword, 'profile');
    expect(repository.lastQuery.startAt, DateTime.utc(2026, 6, 1));
    expect(repository.lastQuery.endAt, DateTime.utc(2026, 6, 18));

    await tester.tap(find.byKey(const Key('events-page-size-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('50 / page').last);
    await tester.pumpAndSettle();
    expect(repository.lastQuery.pageSize, 50);
    expect(repository.lastQuery.page, 1);

    await tester.tap(find.byKey(const Key('events-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastQuery.page, 2);

    await tester.tap(find.byKey(const Key('events-reset-filters-button')));
    await tester.pumpAndSettle();
    expect(repository.lastQuery, _matchesQuery(const EventQuery(pageSize: 50)));
  });

  testWidgets('opens old React event detail drawer fields', (tester) async {
    final repository = _FakeEventRepository(items: [_fullEvent()]);

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('event-detail-evt-1-button')));
    await tester.pumpAndSettle();

    expect(find.text('Event Details'), findsOneWidget);
    expect(find.text('evt-1'), findsWidgets);
    expect(find.text('audit'), findsOneWidget);
    expect(find.text('user.login'), findsWidgets);
    expect(find.text('auth'), findsWidgets);
    expect(find.text('info'), findsWidgets);
    expect(find.text('delivered'), findsOneWidget);
    expect(find.text('visual-qa'), findsWidgets);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('user / 42'), findsOneWidget);
    expect(find.text('trace-123'), findsOneWidget);
    expect(find.textContaining('"ip": "127.0.0.1"'), findsOneWidget);
  });

  testWidgets('renders mobile event cards', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 820));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeEventRepository(items: [_fullEvent()]);

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('events-mobile-layout')), findsOneWidget);
    expect(find.byKey(const Key('event-tile-evt-1')), findsOneWidget);
    expect(find.text('visual-qa-admin logged in'), findsOneWidget);
    expect(find.text('AUDIT'), findsOneWidget);
  });

  testWidgets('renders loading, empty, and error states', (tester) async {
    final completer = Completer<EventPage>();
    await tester.pumpWidget(
      MaterialApp(
        home: EventsPage(repository: _CompletingEventRepository(completer)),
      ),
    );
    await tester.pump();
    expect(find.text('Loading event stream...'), findsOneWidget);
    completer.complete(
      const EventPage(items: [], page: 1, pageSize: 20, total: 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('No events yet'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: _FailingEventRepository())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Event center unavailable'), findsOneWidget);
  });

  testWidgets('prepends realtime events and ignores duplicate ids', (
    tester,
  ) async {
    final repository = _FakeEventRepository(items: [_fullEvent()]);

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    repository.emit(
      _fullEvent(
        id: 'evt-2',
        kind: EventKind.platform,
        message: 'Boss profile requires review',
      ),
    );
    repository.emit(
      _fullEvent(id: 'evt-1', message: 'Duplicate should be ignored'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Boss profile requires review'), findsOneWidget);
    expect(find.text('visual-qa-admin logged in'), findsOneWidget);
    expect(find.text('Duplicate should be ignored'), findsNothing);
  });
}

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({required this.items, this.total});

  final List<EventFeedItem> items;
  final int? total;
  final _controller = StreamController<EventFeedItem>.broadcast();
  final queries = <EventQuery>[];
  final watchQueries = <EventQuery>[];

  EventQuery get lastQuery => queries.last;

  @override
  Future<EventPage> listEvents({EventQuery query = const EventQuery()}) async {
    queries.add(query);
    final filtered = items.where((item) => _matches(item, query)).toList();
    return EventPage(
      items: filtered,
      page: query.page,
      pageSize: query.pageSize,
      total: total ?? filtered.length,
    );
  }

  @override
  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()}) {
    watchQueries.add(query);
    return _controller.stream;
  }

  void emit(EventFeedItem item) => _controller.add(item);
}

class _CompletingEventRepository implements EventRepository {
  const _CompletingEventRepository(this.completer);

  final Completer<EventPage> completer;

  @override
  Future<EventPage> listEvents({EventQuery query = const EventQuery()}) {
    return completer.future;
  }

  @override
  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()}) {
    return const Stream.empty();
  }
}

class _FailingEventRepository implements EventRepository {
  @override
  Future<EventPage> listEvents({EventQuery query = const EventQuery()}) {
    throw StateError('events down');
  }

  @override
  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()}) {
    return const Stream.empty();
  }
}

Matcher _matchesQuery(EventQuery expected) {
  return isA<EventQuery>()
      .having((query) => query.filter, 'filter', expected.filter)
      .having((query) => query.eventType, 'eventType', expected.eventType)
      .having((query) => query.category, 'category', expected.category)
      .having((query) => query.severity, 'severity', expected.severity)
      .having((query) => query.source, 'source', expected.source)
      .having((query) => query.keyword, 'keyword', expected.keyword)
      .having((query) => query.startAt, 'startAt', expected.startAt)
      .having((query) => query.endAt, 'endAt', expected.endAt)
      .having((query) => query.page, 'page', expected.page)
      .having((query) => query.pageSize, 'pageSize', expected.pageSize);
}

bool _matches(EventFeedItem item, EventQuery query) {
  if (query.filter != EventFilter.all && item.kind.name != query.filter.name) {
    return false;
  }
  final checks = {
    query.eventType: item.eventType,
    query.category: item.category,
    query.severity: item.severity,
    query.source: item.source,
  };
  for (final entry in checks.entries) {
    final expected = entry.key;
    if (expected != null && expected.isNotEmpty && entry.value != expected) {
      return false;
    }
  }
  final keyword = query.keyword?.toLowerCase();
  if (keyword != null &&
      keyword.isNotEmpty &&
      !item.message.toLowerCase().contains(keyword)) {
    return false;
  }
  return true;
}

EventFeedItem _fullEvent({
  String id = 'evt-1',
  EventKind kind = EventKind.audit,
  String eventType = 'user.login',
  String category = 'auth',
  String severity = 'info',
  String source = 'visual-qa',
  String message = 'visual-qa-admin logged in',
}) {
  return EventFeedItem(
    id: id,
    kind: kind,
    category: category,
    eventType: eventType,
    message: message,
    severity: severity,
    source: source,
    occurredAt: DateTime(2026, 6, 17, 9),
    status: 'delivered',
    userId: 42,
    entityType: 'user',
    entityId: '42',
    traceId: 'trace-123',
    payload: const {'ip': '127.0.0.1', 'role': 'admin'},
  );
}
