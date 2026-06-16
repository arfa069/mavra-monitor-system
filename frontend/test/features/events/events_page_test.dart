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
    expect(find.text('Boss profile challenged'), findsOneWidget);
    expect(find.text('User logged in'), findsNothing);
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
  _FakeEventRepository({required this.eventsByFilter});

  final Map<EventFilter, List<EventFeedItem>> eventsByFilter;
  final _controller = StreamController<EventFeedItem>.broadcast();
  EventFilter lastFilter = EventFilter.all;

  @override
  Future<List<EventFeedItem>> listEvents({
    EventFilter filter = EventFilter.all,
  }) async {
    lastFilter = filter;
    return eventsByFilter[filter] ?? const [];
  }

  @override
  Stream<EventFeedItem> watchEvents({EventFilter filter = EventFilter.all}) {
    return _controller.stream;
  }

  void emit(EventFeedItem item) => _controller.add(item);
}

class _FailingEventRepository implements EventRepository {
  @override
  Future<List<EventFeedItem>> listEvents({
    EventFilter filter = EventFilter.all,
  }) {
    throw StateError('events down');
  }

  @override
  Stream<EventFeedItem> watchEvents({EventFilter filter = EventFilter.all}) {
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
