import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mavra_frontend/features/events/domain/event_models.dart';
import 'package:mavra_frontend/features/events/presentation/events_page.dart';

void main() {
  testWidgets('renders events and reloads when the filter changes', (
    tester,
  ) async {
    final repository = _FakeEventRepository(
      eventsByFilter: {
        EventFilter.all: [
          _event(id: '1', kind: EventKind.audit, message: 'User logged in'),
        ],
        EventFilter.platform: [
          _event(
            id: '2',
            kind: EventKind.platform,
            message: 'Boss profile challenged',
          ),
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('User logged in'), findsOneWidget);

    await tester.tap(find.text('Platform'));
    await tester.pumpAndSettle();

    expect(repository.lastFilter, EventFilter.platform);
    expect(repository.lastQuery.filter, EventFilter.platform);
    expect(find.text('Boss profile challenged'), findsOneWidget);
    expect(find.text('User logged in'), findsNothing);
  });

  testWidgets('applies full filters, pagination, and opens event details', (
    tester,
  ) async {
    final repository = _FakeEventRepository(
      eventsByFilter: {
        EventFilter.all: [
          _event(id: '1', kind: EventKind.audit, message: 'User logged in'),
        ],
      },
      total: 40,
    );

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('events-keyword-field')),
      'profile',
    );
    await tester.enterText(
      find.byKey(const Key('events-type-field')),
      'user.login',
    );
    await tester.enterText(
      find.byKey(const Key('events-category-field')),
      'auth',
    );
    await tester.enterText(
      find.byKey(const Key('events-severity-field')),
      'warning',
    );
    await tester.enterText(find.byKey(const Key('events-source-field')), 'api');
    await tester.enterText(
      find.byKey(const Key('events-start-field')),
      '2026-06-01T00:00:00Z',
    );
    await tester.enterText(
      find.byKey(const Key('events-end-field')),
      '2026-06-18T00:00:00Z',
    );
    await tester.tap(find.byKey(const Key('events-apply-filters-button')));
    await tester.pumpAndSettle();

    expect(repository.lastQuery.keyword, 'profile');
    expect(repository.lastQuery.eventType, 'user.login');
    expect(repository.lastQuery.category, 'auth');
    expect(repository.lastQuery.severity, 'warning');
    expect(repository.lastQuery.source, 'api');
    expect(repository.lastQuery.startAt, DateTime.utc(2026, 6, 1));
    expect(repository.lastQuery.endAt, DateTime.utc(2026, 6, 18));

    await tester.tap(find.byKey(const Key('events-next-page-button')));
    await tester.pumpAndSettle();
    expect(repository.lastQuery.page, 2);

    await tester.tap(find.byKey(const Key('event-detail-1-button')));
    await tester.pumpAndSettle();
    expect(find.text('Event details'), findsOneWidget);
    expect(find.text('status'), findsOneWidget);
    expect(find.text('test'), findsOneWidget);
  });

  testWidgets('renders an empty event state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EventsPage(
          repository: _FakeEventRepository(eventsByFilter: const {}),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No events yet'), findsOneWidget);
  });

  testWidgets('renders an event error state', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: _FailingEventRepository())),
    );

    await tester.pumpAndSettle();

    expect(find.text('Event center unavailable'), findsOneWidget);
  });

  testWidgets('applies realtime event updates', (tester) async {
    final repository = _FakeEventRepository(
      eventsByFilter: {
        EventFilter.all: [
          _event(id: '1', kind: EventKind.system, message: 'Worker started'),
        ],
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: EventsPage(repository: repository)),
    );
    await tester.pumpAndSettle();

    repository.emit(
      _event(id: '2', kind: EventKind.platform, message: 'JD profile updated'),
    );
    await tester.pumpAndSettle();

    expect(find.text('JD profile updated'), findsOneWidget);
    expect(find.text('Worker started'), findsOneWidget);
  });
}

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({required this.eventsByFilter, this.total});

  final Map<EventFilter, List<EventFeedItem>> eventsByFilter;
  final int? total;
  final _controller = StreamController<EventFeedItem>.broadcast();
  EventFilter lastFilter = EventFilter.all;
  EventQuery lastQuery = const EventQuery();

  @override
  Future<EventPage> listEvents({EventQuery query = const EventQuery()}) async {
    lastFilter = query.filter;
    lastQuery = query;
    final items = eventsByFilter[query.filter] ?? const [];
    return EventPage(
      items: items,
      page: query.page,
      pageSize: query.pageSize,
      total: total ?? items.length,
    );
  }

  @override
  Stream<EventFeedItem> watchEvents({EventQuery query = const EventQuery()}) {
    return _controller.stream;
  }

  void emit(EventFeedItem item) => _controller.add(item);
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

EventFeedItem _event({
  required String id,
  required EventKind kind,
  required String message,
}) {
  return EventFeedItem(
    id: id,
    kind: kind,
    category: 'runtime',
    eventType: 'status',
    message: message,
    severity: 'info',
    source: 'test',
    occurredAt: DateTime.utc(2026, 6, 16, 8),
  );
}
