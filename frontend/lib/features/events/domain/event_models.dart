enum EventKind { audit, system, platform }

enum EventFilter { all, audit, system, platform }

class EventFeedItem {
  const EventFeedItem({
    required this.id,
    required this.kind,
    required this.category,
    required this.eventType,
    required this.message,
    required this.severity,
    required this.source,
    required this.occurredAt,
  });

  final String id;
  final EventKind kind;
  final String category;
  final String eventType;
  final String message;
  final String severity;
  final String source;
  final DateTime occurredAt;
}

abstract class EventRepository {
  Future<List<EventFeedItem>> listEvents({
    EventFilter filter = EventFilter.all,
  });

  Stream<EventFeedItem> watchEvents({EventFilter filter = EventFilter.all});
}

extension EventFilterApiValue on EventFilter {
  String? get apiValue => switch (this) {
    EventFilter.all => null,
    EventFilter.audit => 'audit',
    EventFilter.system => 'system',
    EventFilter.platform => 'platform',
  };
}

extension EventKindLabel on EventKind {
  String get label => switch (this) {
    EventKind.audit => 'Audit',
    EventKind.system => 'System',
    EventKind.platform => 'Platform',
  };
}
